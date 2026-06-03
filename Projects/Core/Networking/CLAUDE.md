<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# Networking

HTTP 클라이언트 + 요청/응답 추상화. Data 레이어가 이걸로 통신한다.

- 식별자: `ModuleType.core(.networking)` / 의존: 없음(순수 기술)

## 핵심 구조

- `NetworkingRequestable.request(_ endPoint: Endpoint) async throws -> Data` — **raw `Data` 반환** (디코딩은 호출 측/Service 책임).
- `Endpoint` 프로토콜: method/baseURL/path/queryItems/headers/body + **`requireTokenRefresh`** (401 시 토큰 갱신 시도 여부). `urlRequest` 기본 구현 제공.
- `NetworkingError`: `invalidURL / decoding / responseFailure(code, body) / requiresReauthentication / unknown(Error)`.
- `AuthSessionRefreshing.refreshSession() async throws -> Bool` — 401 재인증 훅 (구현체는 AuthData의 `AuthSessionRefresher`).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **토큰 갱신 요청 자체의 Endpoint는 `requireTokenRefresh = false`** 여야 한다 (프로토콜 주석). 안 그러면 갱신→401→갱신 무한 루프.
- 도메인을 모른다 — `NetworkingError`를 `RepositoryError`로 바꾸는 건 BaseData(`toRepositoryError()`) 책임. 여기서 하지 말 것.
