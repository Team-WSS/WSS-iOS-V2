<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# RecommendationDomain

홈 화면 추천 도메인 — 오늘의 발견 / 트렌딩 피드 / 관심 피드 / 선호 장르 작품 / 소소픽.

- 식별자: `ModuleType.domain(.recommendation)` / 의존: `BaseDomain`

## 핵심 시나리오

- **`LoadHomeDataUseCase`가 핵심**: Repository의 3개 호출(today/trending/preference)을 **`async let`으로 동시에**
  부르고, 캐시된 닉네임을 얹어 `HomeData` 하나로 합친다. 홈 진입 시 이걸 부른다.
- 소소픽(`LoadSosoPickUseCase`)은 별도.
- 일부는 상태 래퍼 반환: `InterestFeedState`, `PreferenceGenreNovelState` (미설정·빈 상태 등 표현).

## 주의사항 (작업 중 발견 시 누적)

- **`HomePrefetchStore`(actor)는 single-shot이지 TTL 캐시가 아니다**(#225) — 홈은 "탭 복귀마다 갱신" 계약이라
  TTL이면 복귀 때 stale이 나온다. consume이 슬롯을 비우는 걸 "버그 같다"고 고치지 말 것. 채우는 쪽은
  런치 부트스트랩(SplashData), 소비하는 쪽은 `DefaultRecommendationRepository`, 단일 인스턴스는 App DI가 만든다.
  - 슬롯은 **today·trending·taste 3개**다(taste는 2026-08-31 추가 — 처음엔 "느린 개인화라 제외"였으나,
    홈 첫 페인트가 세 호출을 **한꺼번에 기다리는 원자적 렌더**라 하필 제일 느린 taste를 안 데우면
    첫 페인트가 그 왕복에 붙잡혀 **프리페치 이득이 0**이 된다는 게 확인돼 뒤집었다. 개인화 프리페치가
    허용되는 전제는 "비로그인 진입 불가" — 상세는 `SplashData`/`RecommendationData` 문서와 TODO 11절).
- ⚠️ **소비 창은 "첫 consume 시도"까지만 열려 있다 — 빈 슬롯을 소비하려 한 경우에도 닫힌다**(#225 리뷰).
  프리페치는 fire-and-forget이라 홈 첫 로드보다 **늦게 착지할 수 있는데**, 창을 안 닫으면 그 값이 남아 있다가
  다음 탭 복귀 갱신에서 소비돼 **런치 시점 데이터가 뒤늦게 화면에 뜬다**. `Slot.isClosed`를 "쓸데없는 플래그"로
  보고 걷어내지 말 것 — 걷어내면 위 stale이 그대로 살아난다.
  - 그래서 **"소비 후 재fill → 다시 소비"는 이제 성립하지 않는다**(그 명세의 옛 테스트는 교체됐다).
    로그아웃→재로그인처럼 부트스트랩이 두 번 도는 경로에서 두 번째 프리페치는 폐기된다 — 그게 자기 값을
    되먹는 순환보다 안전하다는 판단이다.

- ⚠️ **관심글(`fetchInterestFeeds`)은 `LoadHomeDataUseCase`가 일부러 호출하지 않는다**(#179). 홈 디자인에
  관심글 섹션이 없어서다 — 구 WSSiOS 홈에서도 이미 미사용이었다. Entity·Repository·DTO는 남겨뒀으니
  섹션이 부활하면 되살려 쓰면 된다. **"4개 다 부르는 게 자연스럽다"고 되돌리지 말 것**: 하나라도 실패하면
  홈 전체가 실패하므로, 화면에 안 쓰는 호출을 끼우면 홈이 함께 죽을 확률만 올라간다.
- ⚠️ **3개 호출을 순차(`try await` 연속)로 펴지 말 것 — 한 번 그렇게 퇴행한 적이 있다.**
  원래 `async let`이었는데 `c1e19ed0`(*[Chore] #51 - throws 타입 통일*)에서 순차로 바뀌었다. 커밋 의도는
  타입 통일이었고 병렬성 얘기는 메시지에 없다 — 아래 컴파일 함정을 피하려다 딸려온 부수 피해다.
  (실측 차이: 순차 0.34~0.52s ↔ 병렬 0.16~0.19s. 홈은 탭 복귀마다 갱신하니 매번 낸다.)
- ⚠️ **`async let`은 타입 지정 throw(`throws(RepositoryError)`)를 `any Error`로 지운다.**
  그래서 `throws(RepositoryError)` 함수 안에서 `try await`로 수확하면 *"thrown expression type 'any Error'
  cannot be converted"* 로 컴파일이 깨진다. **병렬성을 포기하지 말고** `do/catch`로 감싸
  `catch let error as RepositoryError { throw error } catch { throw .unknown }` 로 되돌리면 된다.
  (감싸는 함수가 비-throw면 이 문제가 안 보인다 — `MypageViewModel`이 그래서 멀쩡하다.)
  - ⚠️ **`withThrowingTaskGroup`으로 갈아타도 이 `do/catch`는 사라지지 않는다** — 그쪽도 에러 타입이
    `any Error`다. 게다가 여기는 반환 타입이 셋 다 달라 래퍼 enum + switch 되풀기가 붙어 **더 길어진다**
    (TaskGroup은 같은 타입 N개를 동적으로 돌릴 때 쓰는 도구다). "에러 처리가 지저분하니 TaskGroup"은
    막다른 길이니 다시 시도하지 말 것. 줄이려면 `try await (a, b, c)` 튜플 수확으로 `do` 블록을 한 줄로 만든다.
  - ⚠️ **`Result { try await ... }.mapError { }` 로 감싸는 것도 불가능하다** — `async let` 바인딩은
    escaping/non-escaping 무관하게 **어떤 클로저에도 캡처될 수 없다**(*capturing 'async let' variables is
    not supported*, SE-0317). 아이디어 자체는 맞다(`Result.get()`이 `throws(Failure)`라 타입이 딱 맞는다).
    막힌 건 클로저 캡처 규칙이다. 굳이 하려면 `async let`을 `Task {}` 핸들로 바꿔야 하는데, 그러면
    구조적 동시성을 잃어 **형제 태스크 자동 취소가 사라진다** — 얻는 것보다 잃는 게 크다.
- **`issuesThreeCallsConcurrently` 테스트가 이 UseCase의 퇴행 방지선이다** — 지우거나 약화시키지 말 것.
  위 퇴행이 났을 때 아무 테스트도 안 깨져서 아무도 몰랐다. **벽시계 시간이 아니라 "같은 시각에 겹친 호출 수"**
  (병렬 3 / 순차 1)를 재는 이유는 머신 부하에 흔들리지 않게 하기 위해서다 — 시간 측정으로 "단순화"하면
  CI에서 깜빡이다가 결국 삭제된다.
- **닉네임은 네트워크가 아니라 로컬 캐시**다 — `fetchCachedNickname()`만 `async`·`throws`가 아닌 이유
  (Data가 `AppStorage`의 `.nickname`을 읽는다). 값이 없으면 nil이고, 그 표기는 화면이 정한다.
- ⚠️ **`TodayDiscovery`·`TrendingFeed`에 UI 카피를 되돌리지 말 것**(#179에서 제거). `title`("작품 소개"/
  "{닉네임}의 한마디")·`displayDescription`("스포일러가 포함된 글 보기")이 Domain에 박혀 있었는데, 카피는
  View 몫이라 뺐다(Feature 레이어 규칙). 화면은 `content` enum과 `isSpoiler`로 분기해 문구를 만든다.
