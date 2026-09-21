<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# RecommendationData

`RecommendationDomain.RecommendationRepository` 구현 — 홈 추천 5종 fetch + 닉네임 로컬 조회.

- 식별자: `ModuleType.data(.recommendation)` / 의존: `RecommendationDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `RecommendationDataFactory.makeRepository(network:appStorage:logger:)`

## 주의사항 (작업 중 발견 시 누적)

- Factory 파라미터명이 `client`가 아니라 **`network:`** (다른 모듈과 네이밍 불일치). 조립 코드 작성 시 주의.
- **`prefetchStore:`는 App 조립에서만 주입한다**(#225, 기본 nil) — 주입되면 `fetchTodayDiscoveries`/
  `fetchTrendingFeeds`/`fetchPreferenceGenreNovels`가 부트스트랩 프리페치를 **1회만** 소비하고 이후엔
  전부 네트워크(홈 "탭 복귀마다 갱신" 계약 유지). Demo·테스트에서 nil이면 기존과 완전히 동일하게 동작한다.
  - 홈 추천(today/trending/taste)은 **전부 `requireToken`이다**(2026-08-31 — today/trending을
    `usesTokenIfAvailable`에서 전환. 비로그인 진입이 불가해져 익명 허용의 의미가 없어졌고, 죽은 세션의
    프리페치가 익명 200으로 슬롯을 채우던 세션 전환 함정도 함께 닫힌다 → `SplashDomain/CLAUDE.md`). 소소픽만 공개
    API(`withoutToken`)로 남아 있다. **`usesTokenIfAvailable`로 되돌리지 말 것** — 함정이 부활한다.
- 홈 데이터 합성은 Domain의 `LoadHomeDataUseCase` 책임 — 여기선 개별 fetch만 구현.
- ⚠️ **홈 응답의 장르는 영문 케이스명**(`romanceFantasy`·`BL`·`modernFantasy`)으로 온다 — 작품 상세
  응답이 한글(`로판`·`판타지`)이라 **`NovelMapper`의 장르 매핑을 재사용할 수 없다**(값 자체가 다름).
  그래서 `RecommendationMapper.novelGenre(from:)`를 따로 둔다. `ProfileMapper`의 것과는 같은 영문 표다.
  - 매핑 실패는 `MappingError` → `.invalidData`로 **홈 전체가 실패**한다(레이어 고정 규칙). 서버가 장르를
    새로 추가하면 홈이 통째로 안 뜨므로, 그때는 이 표에 케이스를 더해야 한다.
- ⚠️ **오늘의 발견 카드의 본문 필드가 형태마다 다르다** — 작품 소개 카드(`nickname`·`avatarImage`가 null)는
  `novelDescription`을, 유저 한마디 카드는 그 유저의 `feedContent`를 본문으로 쓴다. 서버가 소개 카드의
  `feedContent`에도 같은 소개글을 넣어주는 경우가 있어 **항상 `feedContent`만 써도 겉보기엔 맞아 보이지만**
  의미가 어긋난다(#179에서 분기하도록 수정). 그래서 **형태 판정에 `feedContent`를 넣지 않는다** —
  넣으면 멀쩡한 소개 카드가 유저 한마디로 뒤집힌다.
  - ⚠️ **불완전한 조합은 눙치지 않고 `MappingError`로 실패시킨다**(→ `.invalidData` → 홈 전체 실패):
    ① `nickname`·`avatarImage` 중 **한쪽만** 온 경우, ② 유저 한마디인데 `feedContent`가 없는 경우.
    폴백(빈 본문·기본 닉네임)으로 덮으면 **내용 없는 말풍선**이나 **한마디가 사라진 소개 카드**가 조용히
    그려진다. 홈이 통째로 죽는 대가가 커 보이지만 **서버 계약상 오지 않는 조합**이라 실질 위험이 없다 —
    `avatarImage`가 옵셔널인 응답은 전 모듈에서 여기뿐이고, 그 이유도 "유저가 없는 소개 카드라서"다
    (다른 응답들은 전부 `String` 필수 → 유저가 있으면 아바타는 항상 온다). #179에서 확인.
- **닉네임은 서버가 아니라 `AppStorage`의 `.nickname`에서 읽는다**(`fetchCachedNickname`). 값을 **쓰는** 쪽은
  `ProfileData`(프로필 조회·수정 시 저장)라, 프로필을 한 번도 안 거친 세션에서는 nil일 수 있다.
- DTO는 **실서버 응답 키와 1:1로 맞춰져 있다**(#179에서 `dev.websoso.kr` 실측 대조). 필드를 지우면 화면이
  조용히 비므로, 바꾸기 전에 실제 응답을 먼저 확인할 것.
