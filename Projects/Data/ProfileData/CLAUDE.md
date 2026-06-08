<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# ProfileData

`ProfileDomain.ProfileRepository` 구현 — 프로필 등록/조회/수정, 닉네임·선호·계정·공개범위. (DTO가 가장 많음)

- 식별자: `ModuleType.data(.profile)` / 의존: `ProfileDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `ProfileDataFactory.makeProfileRepository(client:localStorage:logger:)`

## 핵심 시나리오

- **로컬+서버 혼합 구현**: Factory가 `localStorage: AppStorage`를 받는다. 일부 필드(userID/닉네임/성별/프로필캐릭터ID)는 userDefaults에서 읽고/쓰고, 나머지는 서버에서. (도메인 `ProfileRepository` 주석이 어느 게 로컬인지 명시)
- `ProfileTarget`(.me/.user)에 따라 userID 출처 분기.

## 주의사항 (작업 중 발견 시 누적)

- 로컬/서버 책임이 메서드마다 다름 → 수정 전 `DefaultProfileRepository`에서 해당 메서드가 localStorage를 쓰는지 확인.
