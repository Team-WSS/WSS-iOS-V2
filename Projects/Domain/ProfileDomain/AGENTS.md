<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# ProfileDomain

프로필 도메인 — 등록(온보딩)/조회/수정, 닉네임·선호장르·선호작품, 계정정보, 공개범위. (도메인 중 가장 큼)

- 식별자: `ModuleType.domain(.profile)` / 의존: `BaseDomain`

## 핵심 시나리오

- **`ProfileTarget`로 본인/타인 분기**: `.me`(저장된 userDefaults userID 사용) vs `.user(UserID)`(다른 repository에서 userID 확보). 조회 계열(`fetchUserProfile`, `fetchGenrePreferences`, `fetchNovelPreferences`)이 이 타깃을 받는다.
- **로컬+서버 혼합**: 일부 정보(성별/userID/닉네임/프로필캐릭터ID)는 userDefaults에, 나머지(소개글/선호장르)는 서버에서 가져와 합친다. (`syncUserBasicInfo`, `loadInitialProfile`, `updateProfile` 주석 참고)
- `fetchNovelPreferences`는 NovelDomain과 동일하게 **캐시 키워드 주입** 필요.
- 닉네임 중복 검사 `validateNickname` → `Bool`.

## 주의사항 (작업 중 발견 시 누적)

- 본인/타인 로직이 `ProfileTarget`에 숨어있음 — 새 조회 추가 시 두 케이스 모두 고려.
- userDefaults 저장 책임이 도메인 계약 주석에 박혀있음 (구현은 Data). 어떤 필드가 로컬인지 헷갈리면 `ProfileRepository.swift` 주석 확인.
