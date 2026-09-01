<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# AuthData

`AuthDomain` 구현 + **세션(토큰) 갱신**까지 담당. 인증은 다른 Data 모듈과 결이 다르다.

- 식별자: `ModuleType.data(.auth)` / 의존: `AuthDomain`, `BaseDomain`, `BaseData`, `Networking`, `Keychain`, `Logger`
- 진입점 2개:
  - `AuthDataFactory.makeRepository(client:tokenStore:deviceIdentifierStore:logger:)` → `AuthRepository`
  - `AuthDataFactory.makeSessionRefresher(client:tokenStore:logger:)` → `AuthSessionRefreshing`

## 핵심 시나리오

- **토큰 갱신(`AuthSessionRefresher`)**: `tokenStore`의 refreshToken으로 재발급 요청 → 새 access/refresh를 `tokenStore`에 저장. Networking의 401 자동 재인증 훅(`AuthSessionRefreshing`)에 연결되는 구현체.
- 로그아웃/탈퇴 시 토큰·기기식별자 + **UserDefaults 사용자 스코프 캐시** 정리 책임 (도메인 계약대로, #236).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`makeSessionRefresher`에는 refresher가 붙지 않은 client를 주입**해야 한다 (Factory 주석). 안 그러면 토큰 갱신 요청이 다시 갱신 훅을 타는 **무한 재귀**.
- ⚠️ 로그인 에러는 `RepositoryError`가 아니라 **`AuthError`** 로 변환 (`NetworkingError.toAuthError()`): 4xx→`invalidCredential`, 5xx→`providerUnavailable`, decoding→`invalidData`. 일반 Repository 에러 변환과 다름.
- ⚠️ **로그아웃·탈퇴 성공 시 지우는 사용자 스코프 캐시 목록(`clearUserScopedCache`)은 컴파일러가 완전성을 못 지켜준다**(#236) — `StorageKey`에 **사용자 개인 값** 키(userID·nickname·characterID·gender·birthYear·myLibraryFilter 류)를 새로 추가하면 이 목록에도 같이 넣어야 한다. 빠뜨리면 빌드는 초록인데 **계정을 갈아탄 다음 사용자 화면에 이전 사용자의 값이 비친다**(#236 전까지 실재하던 결함 — 홈 "{닉네임}님을 위한 추천글"이 첫 노출 지점이었다). 정리는 성공 경로에서만 한다 — 서버 호출이 실패하면 세션이 안 끝난 것이라 토큰과 마찬가지로 캐시도 보존.
- ⚠️ **Kakao 로그인의 accessToken은 body가 아니라 `Kakao-Access-Token` 커스텀 헤더로 보내야 한다**(서버 스펙, `KakaoLoginRequestHeader.headers`에 매핑 위치). `AuthEndpoint.additionalHeaders`가 한동안 전 case `nil`로 고정돼 있어 이 헤더가 실제로 전송된 적이 없었다(#196에서 실측 — 항상 401 `AUTH-001`). 새 Endpoint case에 커스텀 헤더가 필요하면 `additionalHeaders`의 `switch self`에 분기를 반드시 추가할 것 — 컴파일은 되니 빠뜨려도 조용히 통과한다.
