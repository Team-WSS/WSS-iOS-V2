<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# RecommendationDomain

홈 화면 추천 도메인 — 오늘의 발견 / 트렌딩 피드 / 관심 피드 / 선호 장르 작품 / 소소픽.

- 식별자: `ModuleType.domain(.recommendation)` / 의존: `BaseDomain`

## 핵심 시나리오

- **`LoadHomeDataUseCase`가 핵심**: Repository의 3개 호출(today/trending/preference)을 **순차 실행**하고
  캐시된 닉네임을 얹어 `HomeData` 하나로 합친다. 홈 진입 시 이걸 부른다.
- 소소픽(`LoadSosoPickUseCase`)은 별도.
- 일부는 상태 래퍼 반환: `InterestFeedState`, `PreferenceGenreNovelState` (미설정·빈 상태 등 표현).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **관심글(`fetchInterestFeeds`)은 `LoadHomeDataUseCase`가 일부러 호출하지 않는다**(#179). 홈 디자인에
  관심글 섹션이 없어서다 — 구 WSSiOS 홈에서도 이미 미사용이었다. Entity·Repository·DTO는 남겨뒀으니
  섹션이 부활하면 되살려 쓰면 된다. **"4개 다 부르는 게 자연스럽다"고 되돌리지 말 것**: `/feeds/interest`는
  `requireToken`이라 순차 호출 특성상 이 하나 때문에 홈 전체가 함께 죽는다.
- `LoadHomeDataUseCase`의 3개 호출은 순차(`await` 연속) — 하나 실패 시 전체 실패. 병렬화/부분 실패 허용이 필요하면 여기 수정.
- **닉네임은 네트워크가 아니라 로컬 캐시**다 — `fetchCachedNickname()`만 `async`·`throws`가 아닌 이유
  (Data가 `AppStorage`의 `.nickname`을 읽는다). 값이 없으면 nil이고, 그 표기는 화면이 정한다.
- ⚠️ **`TodayDiscovery`·`TrendingFeed`에 UI 카피를 되돌리지 말 것**(#179에서 제거). `title`("작품 소개"/
  "{닉네임}의 한마디")·`displayDescription`("스포일러가 포함된 글 보기")이 Domain에 박혀 있었는데, 카피는
  View 몫이라 뺐다(Feature 레이어 규칙). 화면은 `content` enum과 `isSpoiler`로 분기해 문구를 만든다.
