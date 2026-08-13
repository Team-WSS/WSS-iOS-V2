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

## 401 재인증 흐름

서버가 refresh token을 **회전**시키므로 재발급이 동시에 두 번 나가면 나중 것이 폐기된 토큰을 써서 세션 전체가 끊긴다. 이를 세 겹으로 막는다.

1. **coalescing** — 진행 중인 재발급 Task를 공유한다(동시 401 N건 → 재발급 1회).
2. **토큰 세대 비교** — 요청이 쓴 access token이 저장소의 것과 다르면 이미 남이 갱신한 것이므로 **재발급 없이** 새 토큰으로 재시도한다. coalescing만으로는 "갱신 직후 도착한 401"을 못 잡는다.
3. **세션 종료 판정 분리** — refresher가 **4xx로 실패할 때만** 세션 종료로 보고 토큰을 지운다. 통신 실패는 에러를 그대로 전파해 토큰을 보존한다.

재시도는 요청당 최대 2회(`NetworkingClient.maxAuthRetries`)이며, 카운터를 줄이며 `request`로 재귀해 무한 루프를 막는다.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **토큰 갱신 요청 자체의 Endpoint는 `authorization = .withoutToken`** 이어야 한다 (프로토콜 주석). 안 그러면 갱신→401→갱신 무한 루프.
- ⚠️ **`SessionRefreshCoordinator.refresh()`의 "검사 → `inFlight` 저장" 구간에 `await`를 넣지 말 것.** actor는 함수 전체를 잠그지 않고 `await`마다 양보하므로, 그 사이에 suspend가 끼면 두 호출이 모두 "진행 중 없음"을 보고 각자 재발급을 시작한다 — 고친 버그가 그대로 부활한다.
- ⚠️ **인증이 필요한 `NetworkingClient`는 앱 전체에서 하나를 공유**해야 한다. coordinator가 client마다 하나씩 생기므로, client를 화면·모듈마다 새로 만들면 재발급 직렬화가 무의미해진다. (조립부를 만들 때 반드시 지킬 것 — 현재 Demo들은 각자 client를 만든다.)
- `inFlight` 정리는 재발급 Task 자신의 `defer`가 전담한다 — 그래서 "남의 Task를 지우는" 경우가 없어 세대 가드가 필요 없다. **정리를 대기자 쪽으로 옮기면 즉시 필요해진다.**
- 도메인을 모른다 — `NetworkingError`를 `RepositoryError`로 바꾸는 건 BaseData(`toRepositoryError()`) 책임. 여기서 하지 말 것.
