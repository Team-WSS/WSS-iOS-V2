<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# Networking

HTTP 클라이언트 + 요청/응답 추상화. Data 레이어가 이걸로 통신한다.

- 식별자: `ModuleType.core(.networking)` / 의존: `Logger` (순수 기술 — 도메인은 모름)

## 핵심 구조

- `NetworkingRequestable.request(_ endPoint: Endpoint) async throws -> Data` — **raw `Data` 반환** (디코딩은 호출 측/Service 책임).
- `Endpoint` 프로토콜: method/baseURL/path/query/headers/body + **`authorization: AuthorizationPolicy`**(`requireToken` / `withoutToken` / `usesTokenIfAvailable`). `makeURLRequest()` 기본 구현 제공.
- `NetworkingError`: `invalidURL / decoding / responseFailure(code, body) / requestEncodingFailed(Error) / requiresReauthentication / unknown(Error)`.
- `AuthSessionRefreshing.refreshSession() async throws -> Bool` — 401 재인증 훅 (구현체는 AuthData의 `AuthSessionRefresher`).
- `SessionRefreshCoordinator`(actor) — 401 재인증을 직렬화한다. `NetworkingClient`가 refresher를 받으면 내부에서 생성해 소유한다.

## 서버의 토큰 정책 (2026-08-13 dev 서버 실측)

코드만 봐선 알 수 없고, 재인증 설계 전체가 여기 기댄다.

| 사실 | 확인 방법 |
|---|---|
| **refresh token은 1회용** — 이미 쓴 것으로 재발급하면 `401 AUTH-001` | 같은 refresh token으로 `POST /reissue` 두 번 |
| ⚠️ **무효화가 원자적이지 않다** — 완전 동시(같은 배치)로 5건을 쏘면 **전부 200**이지만, **0.1초만 벌어져도 뒤엣것은 401**이다 | 간격 0.1s / 0.5s / 2s 로 2건씩 |
| **재발급된 refresh token끼리는 서로 독립적으로 유효**하다 (family 일괄 폐기 없음) | 동시 발급된 5개를 각각 사용 → 전부 200 |
| 재발급은 **access token 만료 여부와 무관** — refresh만 유효하면 새로 발급 | 만료 전 토큰으로 `POST /reissue` → 200 |
| **이전 access token은 무효화되지 않는다** — 자체 `exp`까지 그대로 유효 | 재발급 후 옛 access token으로 API 호출 → 200 |
| 수명: access **30분**, refresh **14일** | JWT `iat`/`exp` |

→ 1·2번째 줄이 중복 재발급이 세션을 끊는 **직접 원인**이다.
→ 5번째 줄 때문에 아래 2층은 정확성이 아니라 **최적화**(불필요한 왕복·회전 제거)다.
→ 위 수치는 **dev 서버** 실측이고, **prod도 같은 정책**임을 확인받았다(2026-08-13). prod에서 직접 재본 건 아니다.

### 실앱 경로 검증 (#184에서 1회 수행, 재현 레시피)

목이 아니라 **실물 전 계층**(키체인 `DefaultTokenStore` → `AuthSessionRefresher` → `SessionRefreshCoordinator` → 실서버)으로
"동시 401 4건 → 재발급 1회"를 확인했다. 결과: 재발급 1회, 4건 전부 200, `AUTH-001` 0건, 로그인 라우팅 0회.

의심될 때 **다시 만드는 방법** — 이 시나리오는 유효한 refresh token을 소스에 박아야 해서 레포에 남길 수 없다:
1. `HomeFeature/Project.swift`의 `demoDependencies`에 `.module(.data(.auth))` 추가
2. Demo에 시나리오 하나 추가 — `DefaultTokenStore()`에 **만료된 access token + 유효한 refresh token**을 심고,
   `AuthDataFactory.makeSessionRefresher(client:)`에는 **refresher 없는 client**를 주입(무한 재귀 방지)
3. `xcrun simctl launch --console-pty`로 콘솔을 잡아 `POST /reissue` 횟수를 센다
   (`ConsoleLogger`가 `print`라 stdout으로 나온다. macOS엔 `timeout`이 없으니 `perl -e 'alarm N; exec @ARGV'`)

⚠️ **홈이어야 하는 이유**: 앱에서 동시 요청이 나가는 화면이라야 재현된다. 순차 호출 화면에서는 첫 요청이 갱신을
끝낸 뒤 다음 요청이 새 토큰을 읽어 **401 자체가 한 번만 난다.**

## 401 재인증 흐름

refresh token이 1회용이라, 재발급이 동시에 두 번 나가면 나중 것이 반드시 실패하고 세션이 끊긴다. 이를 세 겹으로 막는다.

1. **coalescing** — 진행 중인 재발급 Task를 공유한다(동시 401 N건 → 재발급 1회).
2. **토큰 세대 비교** — 요청이 쓴 access token이 저장소의 것과 다르면 이미 남이 갱신한 것이므로 **재발급 없이** 새 토큰으로 재시도한다. coalescing만으로는 "갱신 직후 도착한 401"을 못 잡는다.
3. **재발급 실패 판정 3분화** — 실패를 셋으로 갈라 처리한다(`SessionRefreshCoordinator`).

| refresher가 실패한 방식 | 토큰 | 상위로 나가는 것 |
|---|---|---|
| `responseFailure(401)` — 서버가 refresh token 자체를 거절 | **삭제** | `requiresReauthentication` |
| `responseFailure(그 밖의 모든 status)` — 응답은 왔으나 갱신 실패 | **보존** | `requiresReauthentication` |
| `decoding` — 200인데 응답 스키마가 깨짐 | **보존** | `requiresReauthentication` |
| 그 밖의 전부(통신 실패·타임아웃·클라이언트 버그) | 보존 | 원래 에러 그대로 전파 |

status를 열거하지 않는다 — 코드(`isRefreshRejected`)도 `responseFailure`면 코드값을 보지 않고,
**토큰 삭제 여부에서만 401을 가른다.** `403`·`429`처럼 표에 없는 응답도 재인증으로 간다.

- **새 토큰을 못 받은 게 확정이면 재인증으로 보낸다** — 갱신이 안 되는 토큰으로 앱을 계속 쓰게 두면 401만 반복된다.
  `decoding`이 여기 끼는 이유: 200이어도 파싱에 실패하면 **저장된 토큰은 낡은 그대로**라 결과가 같다.
  ⚠️ 이때 **재발급 쪽 에러를 그대로 던지면 안 된다.** 위로 나가면 원 요청이 실패한 것처럼 보여
  `toRepositoryError()`가 `/reissue`의 404를 `.notFound`로 바꾸고, 화면이 "없는 리소스"로 오해한다.
- **토큰 삭제는 401뿐** — 5xx 같은 일시적 장애에서 지우면 서버가 복구돼도 세션을 되살릴 수 없다.
- **통신 실패는 세션 상태를 증명하지 않는다** — 여기서 로그아웃시키면 지하철에서 잠깐 끊겼다고 튕긴다(#184 이전 버그).

재시도는 요청당 최대 2회(`NetworkingClient.maxAuthRetries`)이며, 카운터를 줄이며 `request`로 재귀해 무한 루프를 막는다.
⚠️ **1회로 줄이면 안 된다** — 2번(토큰 세대 비교)으로 "남이 갱신해준 토큰으로 재시도"하는 것도 이 카운터를 한 번 쓴다.
1회면 그 요청이 실제 재발급 기회를 잃고 401로 죽는다.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **토큰 갱신 요청 자체의 Endpoint는 `authorization = .withoutToken`** 이어야 한다 (프로토콜 주석). 안 그러면 갱신→401→갱신 무한 루프.
- ⚠️ **`SessionRefreshCoordinator.refresh()`의 "검사 → `inFlight` 저장" 구간에 `await`를 넣지 말 것.** actor는 함수 전체를 잠그지 않고 `await`마다 양보하므로, 그 사이에 suspend가 끼면 두 호출이 모두 "진행 중 없음"을 보고 각자 재발급을 시작한다 — 고친 버그가 그대로 부활한다.
- ⚠️ **탈퇴 유저(`404` + `USER-006`)는 위 표를 타지 않는다.** refresher도 `NetworkingClient`로 `/reissue`를 부르므로,
  그 응답이 USER-006이면 **안쪽 client가 먼저 토큰을 지우고** `requiresReauthentication`을 던진다 → coordinator의
  catch(`isRefreshRejected`)는 `responseFailure`가 아니라 그냥 통과시킨다. 결과(토큰 삭제 + 로그인)는 의도대로지만,
  **"404는 토큰 보존"이라는 표만 보고 판단하면 어긋나 보인다.** 토큰을 지우는 자리가 두 곳이라는 걸 알고 볼 것.
- ⚠️ **인증이 필요한 `NetworkingClient`는 앱 전체에서 하나를 공유**해야 한다. coordinator가 client마다 하나씩 생기므로, client를 화면·모듈마다 새로 만들면 재발급 직렬화가 무의미해진다. (조립부를 만들 때 반드시 지킬 것 — 현재 Demo들은 각자 client를 만든다.)
- ⚠️ **`inFlight` 정리는 재발급 Task 자신의 `defer`가 전담한다 — 대기자 쪽(`await task.value` 뒤)으로 옮기지 말 것.** 거기서만 비워지므로 "남의 Task를 지우는" 경우가 원천적으로 없다. 대기자는 여럿이라 늦게 깬 쪽이 그 사이 시작된 새 Task를 지울 수 있고, 그걸 막으려면 세대 카운터 같은 곁가지 상태가 붙는다. **정리 위치를 지키는 것이 그 복잡도를 통째로 없애는 조건**이므로, 옮기고 가드를 더하는 방향으로 가지 않는다.
- 도메인을 모른다 — `NetworkingError`를 `RepositoryError`로 바꾸는 건 BaseData(`toRepositoryError()`) 책임. 여기서 하지 말 것.
