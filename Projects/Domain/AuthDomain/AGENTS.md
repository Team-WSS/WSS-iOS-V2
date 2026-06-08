<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# AuthDomain

인증 도메인 — 소셜 로그인 / 로그아웃 / 탈퇴 / Apple 인증 동기화.

- 식별자: `ModuleType.domain(.auth)` / 의존: `BaseDomain`

## 핵심 시나리오

- **로그인(`SocialLoginUseCase`)**: `SocialLoginCredential` → `NeedOnboarding` 반환 (온보딩 필요 여부로 분기).
- **Apple 동기화(`SyncAppleCredentialUseCase`)**: 앱 소유자 변경 대응 — 기존 Apple 사용자의 새 인증 정보로 서버 사용자 정보를 갱신.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`login`만 `throws(AuthError)`** 를 쓴다 (다른 레이어 표준인 `RepositoryError`가 아님). `AuthError`: `networkUnavailable / invalidCredential / providerUnavailable / invalidData / unknown`. 로그인 외(logout/withdraw/sync)는 `RepositoryError`.
- `logout`/`withdraw`는 서버 호출뿐 아니라 **로컬 토큰·개인정보 삭제까지** 책임 (프로토콜 주석 명시).
