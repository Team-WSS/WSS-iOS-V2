<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# ProfileDomain

프로필 도메인 — 등록(온보딩)/조회/수정, 닉네임·선호장르·선호작품, 계정정보, 공개범위. (도메인 중 가장 큼)

- 식별자: `ModuleType.domain(.profile)` / 의존: `BaseDomain`

## 핵심 시나리오

- **`ProfileTarget`로 본인/타인 분기**: `.me`(저장된 userDefaults userID 사용) vs `.user(UserID)`(다른 repository에서 userID 확보). 조회 계열(`fetchUserProfile`, `fetchGenrePreferences`, `fetchNovelPreferences`)이 이 타깃을 받는다.
- **로컬+서버 혼합**: 일부 정보(성별/출생연도/userID/닉네임/프로필캐릭터ID)는 userDefaults에, 나머지(소개글/선호장르)는 서버에서 가져와 합친다. (`syncUserBasicInfo`, `loadInitialProfile`, `updateProfile` 주석 참고)
- **`loadAccountInfoDraft()`(서버 GET, email 포함) vs `loadLocalGenderAndBirth()`(userDefaults 우선, email 없음)**: 둘 다 성별/출생연도를 반환하지만 성격이 다르다. 계정정보 화면처럼 email이 필요하면 전자를 쓴다. 후자(성별/나이 변경 등)는 userDefaults를 먼저 보되, **캐시 미스면 `loadAccountInfoDraft()`와 같은 서버 API로 폴백하고 결과를 userDefaults에 캐시**한다 — `syncUserBasicInfo()`/`registerProfile()`이 출생연도를 로컬에 쓰지 않아서, "성별/나이 변경" 화면을 한 번도 저장한 적 없는 사용자는 로컬 캐시가 항상 비어있기 때문(이 폴백이 없으면 `notFound`로 실패하고, 화면이 이를 삼키면 하드코딩 기본값으로 서버 값을 덮어쓸 위험이 있었다). `saveAccountInfo(_:)`는 서버 PUT 성공 시 userDefaults(성별/출생연도)도 함께 갱신한다.
- `fetchNovelPreferences`는 NovelDomain과 동일하게 **캐시 키워드 주입** 필요.
- 닉네임 중복 검사 `validateNickname` → `Bool`.

## 주의사항 (작업 중 발견 시 누적)

- **`BirthYear.maxYear`는 하드코딩이 아니라 현재 연도(`Calendar.current...`) 계산값**(#222) — 생년 휠 상한이
  이 값을 그대로 쓴다(`WSSBirthYearWheel`, OnboardingFeature·SettingFeature 공용). 고정값으로 되돌리면 해가
  바뀔 때마다 stale해진다(V1·구 V2가 2025/2024 하드코딩이라 그랬다). `Foundation` import가 이 때문에 필요하다.
- 본인/타인 로직이 `ProfileTarget`에 숨어있음 — 새 조회 추가 시 두 케이스 모두 고려.
- userDefaults 저장 책임이 도메인 계약 주석에 박혀있음 (구현은 Data). 어떤 필드가 로컬인지 헷갈리면 `ProfileRepository.swift` 주석 확인.
- `GenrePreference.genre`는 자유 문자열이 아니라 `BaseDomain.NovelGenre`(9개 케이스) 타입이다 — 서버가 그 9개 밖의 장르 토큰을 내려주면 Data의 `novelGenre(from:)` 매핑이 실패해 `RepositoryError.invalidData`로 전파된다(예전엔 임의 문자열을 그대로 통과시켰음). 표시용 한글 라벨/아이콘은 `WSSComponent`의 `NovelGenre+Presentation`(`displayName`/`iconImage`) 재사용.
- `NovelPreference.keywords`는 `[KeywordPreference]` **배열**이라 서버 응답 순서를 그대로 보존한다. 과거엔 `[Keyword: Int]` Dictionary라 매핑(`ProfileMapper.novelPreference`) 단계에서 순서가 소실됐었다 — Dictionary로 되돌리면 같은 문제가 재발하니 주의.
- `fetchGenrePreferences`가 반환하는 `[GenrePreference]`는 **서버가 이미 개수 내림차순으로 정렬해 내려준다** — 클라이언트(Feature)에서 재정렬하지 않는다. 매핑(`ProfileMapper.genrePreferences`)도 배열 `.map`이라 순서를 그대로 보존한다.
- `validateNickname(_:)`의 `Bool` 반환은 **`true` = 사용 가능(중복 아님)** 이다("검증 통과"가 아니라 "가용"으로 읽을 것). `ProfileData`의 `NicknameValidationResponse.isValid`를 그대로 전달한다.
- `ProfileDraft.removeGenrePreference(_:)`는 `GenrePreference`의 **완전 일치(Equatable: genre+count)** 비교로 제거한다 — `GenrePreference(genre: someGenre, count: 0)`처럼 count를 임의로 채운 새 값으로는 지워지지 않고 조용히 실패한다. 토글 등에서 제거하려면 `genrePreferences.first(where: { $0.genre == genre })`로 draft에 실제 들어있는 인스턴스를 찾아 그대로 넘겨야 한다.
- `ProfileDraft.updateIntroduction(_:)`은 더 이상 3줄 제한을 하지 않는다(50자 길이만 즉시 clamp). 3줄 제한은 별도 `truncateIntroductionToLineLimit()`로 분리됐고, 호출자(Feature)가 **제출 직전에 직접 호출**해야만 적용된다 — 안 부르면 4줄 이상도 그대로 저장됨. 이 메서드는 `\n` 개수만 세므로 워드랩으로 시각적으로 3줄을 넘는 입력은 걸러내지 못한다(예전 UIKit `NSLayoutManager` 기반 실시간 검증을 걷어내고 단순화한 결과 — Feature `MyPageEditView` 참고).
