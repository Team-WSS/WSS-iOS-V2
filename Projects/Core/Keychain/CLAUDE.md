<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# Keychain

보안 저장소 래퍼. 토큰/기기 식별자를 키체인에 보관.

- 식별자: `ModuleType.core(.keychain)` / 의존: 없음

## 핵심 구조

- `KeychainStore` (저수준): `create`/`read`/`update`/`save`/`delete`.
- `TokenStore` (고수준): `saveAccessToken`/`saveRefreshToken`/`accessToken()`/`refreshToken()`/`clearTokens()`. → AuthData가 토큰 갱신·로그아웃에 사용.
- `DeviceIdentifierStore`: 기기 식별자.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ `KeychainStore` 의미 구분: **`create`는 기존 key 있으면 실패**, **`update`는 key 없으면 실패**, **`save`는 upsert**(있으면 수정/없으면 생성). 토큰 재저장은 보통 `save`/`update` 계열을 써야 함.
- `read`는 없으면 `nil` 반환 (에러 아님).
