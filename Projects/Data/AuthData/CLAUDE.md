<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# AuthData

`AuthDomain` 구현 + **세션(토큰) 갱신**까지 담당. 인증은 다른 Data 모듈과 결이 다르다.

- 식별자: `ModuleType.data(.auth)` / 의존: `AuthDomain`, `BaseData`, `Networking`, `Keychain`
- 진입점 2개:
  - `AuthDataFactory.makeRepository(client:tokenStore:deviceIdentifierStore:logger:)` → `AuthRepository`
  - `AuthDataFactory.makeSessionRefresher(client:tokenStore:logger:)` → `AuthSessionRefreshing`

## 핵심 시나리오

- **토큰 갱신(`AuthSessionRefresher`)**: `tokenStore`의 refreshToken으로 재발급 요청 → 새 access/refresh를 `tokenStore`에 저장. Networking의 401 자동 재인증 훅(`AuthSessionRefreshing`)에 연결되는 구현체.
- 로그아웃/탈퇴 시 토큰·기기식별자 정리 책임 (도메인 계약대로).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`makeSessionRefresher`에는 refresher가 붙지 않은 client를 주입**해야 한다 (Factory 주석). 안 그러면 토큰 갱신 요청이 다시 갱신 훅을 타는 **무한 재귀**.
- ⚠️ 로그인 에러는 `RepositoryError`가 아니라 **`AuthError`** 로 변환 (`NetworkingError.toAuthError()`): 4xx→`invalidCredential`, 5xx→`providerUnavailable`, decoding→`invalidData`. 일반 Repository 에러 변환과 다름.
