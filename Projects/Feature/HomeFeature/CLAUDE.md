<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# HomeFeature

앱의 홈(탭) 화면 — 오늘의 발견 / 트렌딩 피드 / 관심 피드 / 선호 장르 작품을 한 화면에 모아 보여준다.

- 식별자: `ModuleType.feature(.home)` / 의존: `BaseDomain`, **`RecommendationDomain`**(홈의 Domain 코드가
  별도 `HomeDomain`이 아니라 여기 있음 — `LoadHomeDataUseCase`·`HomeData`·`TodayDiscovery`·`TrendingFeed`·
  `PreferenceGenreNovelState`), **`NotificationDomain`**(알림 벨 배지), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `HomeFactory.makeView(loadHomeDataUseCase:loadUnreadNotificationStatusUseCase:logger:
  onNovelSelected:onFeedSelected:onSearchTapped:onDetailSearchTapped:onNotificationTapped:
  onPreferenceGenreSettingTapped:onAuthenticationRequired:)` — **탭 콘텐츠만** 반환(탭바·화면 전환은 App 몫)

## 핵심 시나리오

- **로드**: `onAppear`마다 `.load` → `LoadHomeDataUseCase`(추천 3종)와 `LoadUnreadNotificationStatusUseCase`
  (알림 배지)를 **한 흐름**으로 부른다. 하나라도 실패하면 홈 전체가 실패다.
- **섹션 4개**: 검색바·상세검색 배너 / 오늘의 발견(가로 캐러셀) / {닉네임}님을 위한 추천글(2개씩 3페이지) /
  이 웹소설은 어때요?(2열 그리드, 선호장르 미설정이면 설정 유도 CTA).
- 선택 결과는 전부 콜백으로 상위에 위임한다 — 이 화면은 스스로 화면을 전환하지 않는다.

## 화면 동작 계약

- (Figma 대조 단계 3B에서 확인받은 것만 채운다)

## 주의사항 (작업 중 발견 시 누적)

- 홈 Domain을 찾을 때 `HomeDomain`을 만들지 말 것 — 정본은 `RecommendationDomain/Sources/`다
  (`LibraryFeature`↔`NovelDomain`과 같은 형태의 이름 불일치).
- ⚠️ **`.load`에 "최초 1회" 가드를 넣지 말 것** — 홈은 밖(피드 작성·선호장르 설정·알림 확인)에서 바뀐 값을
  다시 비춰야 해서 **탭 복귀마다 갱신**하기로 정했다(구 WSSiOS도 `viewWillAppear`마다 전체를 다시 불렀다).
  중복 요청은 `loadTask` 가드가 막는다. `LibraryFeature`의 `hasLoaded` 패턴을 그대로 옮겨오지 말 것.
- ⚠️ **홈은 탭 콘텐츠라 VM이 앱 세션 내내 산다** → `requiresAuthentication`을 View가 소비한 뒤
  `.consumeAuthenticationRequired`로 되돌려야 2회차 인증 만료가 삼켜지지 않는다(`LibraryFeature`와 같은 이유).
  그 대가로 콜백이 여러 번 발화할 수 있으니 **`onAuthenticationRequired`는 idempotent해야 한다.**
- `state.preferenceGenreNovelState`는 **옵셔널**이다 — nil(아직 로드 전)과 `.noGenreSettings`(미설정)를
  섞으면 로딩 중에 "선호장르 설정하기" CTA가 번쩍인다.
