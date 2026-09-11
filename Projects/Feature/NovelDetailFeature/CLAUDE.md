<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDetailFeature

소설 상세(NovelDetail) 화면 — 몰입형 헤더 + 유저 평가 + 탭(정보/피드). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.novelDetail)` / 의존: **전용 `NovelDetailDomain`은 없고** `NovelDomain` + `FeedDomain`(피드 탭·좋아요·삭제) + `NovelReviewDomain`(평가 삭제) + `SocialDomain`(피드 신고) + `NotificationDomain`(작품 알림 등록 시트, #189)을 쓴다
- 진입점: `NovelDetailFeatureFactory.makeView(...)` — UseCase 12종 + `onRoute: (NovelDetailRoute) -> Void`(화면 전환 의도 7케이스, 정본은 `Sources/Navigation/NovelDetailRoute.swift`) + `onAuthenticationRequired`(#253에서 클로저 7개를 Route enum 하나로 통합 — 이 모듈이 그 패턴의 파일럿) + `needsFeedReloadForCreatedFeed: Binding<Bool>`(#256 — 이 화면발 피드 작성 성공 복귀 신호, App 탭 Root 로컬 `@State`와 연결. `NovelDetailAssembly` 쪽은 배선 누락을 컴파일러가 잡게 기본값 없음). 호출자(App)는 exhaustive switch로 자기 `Destination`에 매핑한다.
  - **`.review(NovelInformation, ReadingStatus)`**: 평가 화면 진입. status는 평가 초안 seed — 평가 없음/있음 모두 상태바에서 탭한 상태(평가 있음의 칩·여백 탭만 현재 상태). 화면 전환은 호출자(App)가 NovelReviewFactory로 조립.
  - **`.createFeed(ConnectedNovel)`**: 피드 작성 진입 — "나도 한마디" 버튼과 피드 탭 플로팅 버튼이 공유.
    지금 보고 있는 작품을 `Novel → ConnectedNovel`로 변환해 넘긴다(`NovelDetailView.connectedNovel(from:)`,
    `genre`는 `Novel.genres.first` — 검색 결과 연결과 같은 변환 규칙, `CreateFeedViewModel.confirmSelectedNovel`
    참고). 호출자(App)가 이 값을 `FeedFeatureFactory.makeCreateFeedView(connectedNovel:)`에 그대로 넘기면
    작성 화면이 그 작품이 이미 연결된 상태로 뜬다(#197).
  - **`.authorSearch(String)`**: 작가 검색 화면 진입 — 헤더 작품 정보의 **작가 이름 탭**. 전달값은 탭한 **작가 한 명**의 이름(다작가면 이름별 개별 버튼). 화면 전환은 호출자(App)가 수행 — App(`NovelDetailAssembly`)이 이 이름을 그대로 `SearchAssembly.makeView(initialQuery:)`에 넘겨, "일반 검색" 화면이 그 작가 이름으로 **이미 검색 실행된 결과**부터 보여준다(#197 — 전용 작가 검색 화면이 따로 있는 게 아니라 `SearchNovelUseCase.searchByText`가 제목/작가 구분 없는 단일 텍스트 검색이라 기존 화면 재사용으로 충분).
  - **`onAuthenticationRequired()`**: 인증 만료(`RepositoryError.authenticationRequired`) 시 로그인 유도 콜백. **화면 전환 "의도"가 아니라 세션 이벤트라 `onRoute`에 합치지 않는다**(#253 설계 결론). **화면 내 모든 서버 호출 공통** — VM이 `state.requiresAuthentication` 신호만 세우고(어느 catch에서 발생하든 `presentError`/`loadNovel` 경유 `routeToLoginIfAuthenticationRequired`로 수렴), View가 `onChange`로 소비해 콜백 발화(`shouldDismiss`→`dismiss`와 대칭). 인증 만료면 개별 실패 토스트/실패 뷰 대신 이 신호만 낸다.

## 핵심 시나리오

- **로드**: 첫 진입은 `LoadNovelUseCase`로 전면 스피너와 함께 `NovelInformation` 확보(`hasLoaded` 세움). **재진입(pop 복귀) 시 작품 정보는 조용한 갱신** — `onAppear`가 재진입마다 불리는 걸 이용해, `hasLoaded` 후에도 `load()`가 **스피너 없이** `loadNovel`을 다시 태워 `information`/`novel`을 제자리 교체한다(스크롤 보존, 실패해도 기존 화면 유지 — 평가 화면(push)에서 바뀐 유저 평가·별점·집계가 복귀 즉시 반영, #221 iPhone SE 실측). **피드는 재진입에 목록을 다시 받지 않는다**(#256) — 목록에서 **다녀온 피드**(셀 탭 → 피드 상세, "수정하기" → 수정 — View가 떠나기 직전 `.feedVisited`로 기억)만 복귀 시 피드 상세 API(`LoadFeedDetailUseCase`)로 그 셀을 교체하고(`TotalFeed.updated(from:)`, `.notFound`/`.forbidden`이면 셀 제거·그 외 실패는 셀 유지), **이 화면발 피드 작성 성공 복귀만** `.reloadFeedsForCreatedFeed`(App Binding 신호 소비)가 피드 섹션을 초기 로드처럼 리셋한다(비우고 첫 페이지 재로드 — 새 글이 맨 위. 정보 탭에서 "나도 한마디"로 작성했으면 지연 로드에 맡긴다). 피드 목록은 **피드 탭 첫 진입 시 지연 로드**, 이후 `lastFeedID` 커서 페이지네이션(첫 페이지 커서 0).
  - **2026-09-08 재판정(#256)**: 예전엔 재진입마다 `lastFeedID 0 + size = 보던 개수`로 전체 window를 조용히 재조회했다(V1 parity, #236 — 2026-09-03 "셀 동기화로 바꾸지 말 것" 판정까지 있었다). 그러나 **이 방식은 그 사이 새 글이 생기면 window 끝의 기존 글이 밀려나 "보이던 글이 사라지는" 실결함**이 있다(피드 응답에 `totalCount`가 없어 서재식 delta 보정 불가, 글 2~3개면 스크롤 복구 여지도 없음 — 사용자 실측 보고). 그래서 사용자 확정으로 **SosoFeed식 셀 동기화 + 작성 복귀 리셋으로 완전 통일**하고 `NovelFeedPageSizePolicy`(FeedDomain)도 삭제했다. **판정된 절충**: 이 화면엔 당겨서 새로고침이 없어, **다른 유저의 새 글·변경은 화면을 새로 push하기 전까지 재진입만으론 반영되지 않는다**(2026-09-03 판정이 지키려던 그 성질을 실결함 해소와 맞바꿈).
  - **셀 동기화가 진행 중인 낙관 좋아요를 되덮지 않게 보호한다** — 좋아요 서버 동기화가 아직 도는 셀(`syncingLikeFeedIDs`)은 상세 응답이 토글 이전 스냅샷일 수 있어, `TotalFeed.preservingLikeState`로 **좋아요 두 필드만** 로컬 우선(셀 전체를 로컬로 되돌리면 서버 변경(본문 수정 등)까지 버린다). 전체 재조회 시절의 구간 집합(`likeToggledDuringRefresh`)은 목록 GET이 사라져 함께 제거됐다 — 전체 목록 재조회 병합의 정본은 UserPage·UserFeedList 쪽 참고.
- **관심 토글**: 정책은 엔티티 `Novel.toggleInterest()`에 위임, UI 낙관 반영 후 서버 실패 시 롤백. `isInterested == nil`(비로그인 등)이면 엔티티가 no-op → 서버 호출도 스킵.
- **정보 탭 조건부 표시**: 매력포인트/키워드/읽기상태그래프는 각각 값 없으면 숨김, 전부 없으면 빈 상태(제목도 "독자들의 평가"로 변경). 그래프 우세 상태·동률 우선순위는 도메인 `dominantReadStatus`가 결정.
  - ⚠️ **"독자들의 감상평" 제목의 소속은 매력포인트·키워드뿐**이다 — 읽기 상태 그래프는 제목을 공유하지 않는 별도 섹션. 그래서 **그래프만 있고 매력포인트·키워드가 다 비면 제목까지 통째로 숨긴다**(`hasReviewContent`). 셋 다 없을 때만 빈 상태(`hasAnyReviewSummary`)라는 점과 헷갈리기 쉽다 — 판정이 **두 단계**인 이유가 이것. 그래프 위 구분선도 감상평이 실제로 있을 때만 그린다(나눌 대상이 없으면 선도 없다).
- **작품 알림 등록 시트(#189)**: 네비바 threedots 왼쪽에 종 아이콘을 추가해 탭하면 `NovelNotificationSettingSheet`가 뜬다. 완결 알림/휴재 복귀 알림 두 줄을 `WSSToggleButton`으로 각각 켜고 끈다 — 서버는 `NovelNotificationSetting(isCompletionNotificationEnabled, isHiatusReturnNotificationEnabled)` 전체를 매번 함께 PUT 받는 **멱등** API라, 토글 하나만 눌러도 VM은 현재 스냅샷 전체를 보낸다. 로드는 시트가 열릴 때(`onAppear → .load`), 토글은 **낙관 반영 후 실패 시 롤백**(전면 실패 뷰 대신 토스트만 — 시트가 작아 재시도는 "닫고 다시 열기"로 충분하다고 판단). `isSyncing` 가드로 두 토글의 PUT이 겹치는 걸 막는다(스냅샷 롤백이 꼬이지 않도록 요청 하나씩만 진행). 시트는 `.presentationDetents([.height(178)])` + `.presentationDragIndicator(.hidden)` 고정 높이(콘텐츠가 두 줄뿐이라 드래그로 늘릴 여지가 없어서).
  - **종 아이콘은 둘 중 하나라도 켜져 있으면 채움(`icAnnouncementFill`)+`wssPrimary100`, 아니면 윤곽선(`icAnnouncement`)+`wssBlack`이다**(2026-09-11) — 시트를 열지 않아도 알림이 걸려 있는 작품인지 한눈에 보이게. 이걸 위해 `NovelNotificationSettingSheetViewModel`이 **시트가 열릴 때마다 새로 만들던 것에서 `NovelDetailView` 진입 시 한 번만 만들어 화면 수명 내내 재사용**하는 것으로 바뀌었다(`NovelDetailView.onAppear`가 `.load()`도 함께 태움) — 아이콘은 이 VM의 `state`를 직접 읽어 시트 안 토글도 실시간으로 비춘다. ⚠️ **`isClosing`은 더 이상 "인스턴스가 죽는다"는 뜻이 아니다** — 인스턴스는 안 죽고 재사용되므로, `load()`가 **시트 재진입마다 무조건 `isClosing = false`로 되돌린다**(그 앞의 `hasLoaded` 가드와는 별개 관심사라 순서를 분리해뒀다). 이 리셋이 없으면 시트를 한 번 닫은 뒤 다시 여는 순간부터 토글 가드(`!isClosing`)가 영구히 막혀 아무 반응이 없다. **인증 만료 신호도 시트 내부가 아니라 `NovelDetailView`가 직접 듣는다** — 시트가 안 떠 있을 때도(아이콘 로드) 이 VM이 살아 움직일 수 있는데, `NovelNotificationSettingSheet`의 `.onChange`는 시트가 mount돼 있을 때만 존재해 신호를 놓칠 수 있어서다(그래서 `NovelNotificationSettingSheet`는 이제 `onAuthenticationRequired` 파라미터 자체가 없다).

## Demo 시나리오 (Mock)

Demo 앱의 Mock 모드는 **버튼 하나 = 데이터 조건 하나**다(`DemoScenario`). 화면이 **데이터에 따라 분기하는 지점**만
시나리오로 만든다 — 조건부 섹션·빈 상태·실패 뷰. 필드 하나씩 다른 조합은 버튼만 늘고 볼 게 없어 만들지 않는다.

| 그룹 | 시나리오 | 확인 대상 |
|---|---|---|
| 기본 | 전체 데이터 | 모든 섹션 표시 |
| 내 평가 — 없음 | 내 평가 없음 | 평가 상태바 → 읽기 상태 셀렉터 |
| 내 평가 — 항목 조합 | 읽기 상태만 / 별점+읽기 상태 / 기간+읽기 상태 / 별점+기간+읽기 상태 | 상태바의 별점·기간 **칩이 각각** 나타나고 사라짐 |
| 독자 평가 — 하나만 없음 | 매력포인트 없음 / 키워드 없음 / 읽기 상태 없음 | **그 섹션 하나만** 사라짐 |
| 독자 평가 — 하나만 있음 | 매력포인트만 있음 / 키워드만 있음 / 읽기 상태만 있음 | **그 섹션 하나만** 남음 |
| 독자 평가 — 전부 없음 | 독자 평가 전부 없음 | 감상평 영역 전체가 빈 상태(제목도 "독자들의 평가") |
| 피드 | 피드 없음 / 1개 / 5개 / 15개 / 45개 | 빈 상태 / 셀 하나뿐인 최소 목록 / 페이지네이션 없음(1페이지) / 2페이지 / 5페이지(페이지 크기 10) |
| 극단 | 최소 데이터(신규 작품) | 표지·평점·플랫폼·평가·피드 전부 없음 |
| 실패 | 작품 로드 실패 / 피드 로드 실패 | 화면 전체 NetworkErrorView / **피드 탭 자리만** NetworkErrorView |

- 시나리오는 `userReviewParts`(`Set<UserReviewPart>?`) / `readerReviewParts`(`Set<ReaderReviewPart>`) / `feedCount`(`Int` — 0이면 빈 상태, 페이지 크기 10 기준으로 페이지 수가 갈린다) **축**으로 표현하고 Mock UseCase 둘이 그 축만 읽는다 — 새 조건을 넣을 땐 축(또는 집합의 원소)을 늘리지, `if scenario == ...` 분기를 Mock 곳곳에 흩뿌리지 말 것.
- ⚠️ **`userReviewParts`는 옵셔널 집합** — `nil`(평가 자체가 없음 → 셀렉터)과 `[]`(평가는 있고 **읽기 상태만** 있음 → 칩 없는 상태바)는 **다른 화면**이다. 읽기 상태는 평가가 존재하면 반드시 있으므로 축에 넣지 않는다(그래서 "읽기 상태만" = 빈 집합).
- ⚠️ **기간(`ReadingPeriod`)은 읽기 상태에 따라 채워지는 날짜가 다르다** — 보는 중=**시작일만**, 봤어요=시작+종료, 하차=**종료일만**(시작일 없음 → 표기가 `~ 26. 06. 11`). 이 규칙은 도메인 `ReadingPeriod.normalized(for:)`가 강제하므로 **Mock/테스트 데이터가 흉내내지 말고 그 함수를 태울 것** — 직접 `ReadingPeriod(start:end:)`로 만들면 상태와 모순된 데이터(하차인데 시작일 있음)가 나온다.
- **독자 평가 3요소(매력포인트·키워드·읽기 상태)는 각각 독립** — 하나만 비면 그 섹션만 숨고, 셋이 다 비어야 감상평 영역이 빈 상태로 대체된다. 그래서 "하나만 없음"·"하나만 있음"·"전부 없음"을 각각 별도 시나리오로 둔다. 요소별 Bool 프로퍼티 3개 대신 **채울 부분의 집합** 하나(`readerReviewParts`)로 표현해, 조합이 늘어도 그 switch 한 곳만 고치면 되게 했다.
- ⚠️ **평점 없음은 `rating: nil`이 아니라 `rating: 0` + `ratingCount: 0`** — `Novel.rating`은 non-optional `Float`다.
- ⚠️ **연재중 케이스는 `.onGoing`** (`.serial` 아님 — `NovelPublicationStatus`).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **피드 로드 실패는 첫 페이지든 더보기든 탭 자리를 `NetworkErrorView`(재시도 버튼)로 대체한다**(#195) — 토스트로 알리지 않는다. 규칙 정본은 [Feature CLAUDE.md](../CLAUDE.md)의 "로드 실패 표현 계약".
  - ⚠️ **`NovelDetailFeedTab`은 실패를 목록보다 먼저 판단한다**(`if hasLoadFailed` → `else if feeds.isEmpty`). 더보기가 실패하면 목록이 남아 있는데 그대로 두면 **실패를 알릴 자리가 없어** 사용자가 "왜 안 늘어나지"로 갇힌다(서재에서 실제로 겪었다). 순서를 뒤집지 말 것.
  - ⚠️ **첫 성공 전이면 피드 탭 재진입(`selectTab`)도 첫 페이지 재로드를 시도한다** — 그때 `feedsLoadFailed`를 **함께 내려야** 요청이 도는 동안 실패 뷰 대신 로딩이 보인다. 안 내리면 실패 뷰가 그려진 채 그 재시도 버튼이 `feedsTask == nil` 가드에 막혀 **눌러도 반응이 없다**(#195에서 실제로 그랬다). 단 플래그 하강은 **재로드가 실제로 도는 `if` 블록 안**에 둘 것 — 밖에 두면 더보기 실패 상태에서 탭만 왕복해도 실패 뷰가 사라지고 재시도 수단이 증발한다.
  - 재시도(`.retryFeeds`)는 **첫 페이지부터 다시 세운다** — `state.feeds`를 비우고 `hasLoadedFirstFeeds`도 내린다. 더보기 실패도 이 경로로 오므로 안 비우면 같은 피드가 두 번 붙는다.
  - 한때 첫 페이지 실패는 `"피드를 불러오지 못했어요"` 문구(재시도 버튼 없음) + 토스트였고 더보기 실패는 토스트뿐이었다. 재시도 수단이 "탭 재탭"이라는 숨은 동작뿐이라 바꿨다.
- ⚠️ **미해결 잠재 결함(#236 실측 → #239로 조사 이관): 피드 목록이 변한 직후 화면 전환·오버레이가 겹치면 SwiftUI 레이아웃이 수렴하지 않아 메인 스레드 100% 라이브락**(화면 전체 굳음, 앱 강제종료 외 복구 불가). iPhone 17 Pro 시뮬레이터(iOS 26.4) 실측 5회 — **"피드 3개 상태에서 작성 완료 pop 복귀"는 3/3으로 사실상 결정론적 재현**(피드 4·5개 상태의 같은 조작은 2/2 정상), 그 외 삭제 직후 드롭다운 탭 1회·**삭제 직후 작성 화면 push 1회(재진입 피드 재조회를 끈 빌드에서 발생 → develop에 잠재하던 결함으로 판정, 이 브랜치 변경이 원인 아님)**. 프로세스 샘플 스택은 매번 동일: `LazyVStackLayout` placement(initial↔final)가 진동하며 `NovelDetailFeedTab` 셀 실측·`NovelDetailHeaderView` backdrop이 반복 재평가. `cellTopYs`를 @State→참조 박스로 바꿔 한 겹은 끊었지만 재현이 계속돼 단독 원인이 아니다 — 몰입형 헤더+스티키 탭 `minHeight`+LazyVStack+GeometryReader 다중 조합의 비수렴으로 추정. 실기기 재현 여부 미확인 — 출시 전 확인 필요. 참고로 **수정 완료 복귀(피드 4개)는 정상**이고 복귀 즉시 수정 본문·"(수정됨)" 배지 반영을 실측 확인했다. **#256이 주 재현 경로를 소멸시켰고, 같은 전제조건 재관찰에서 미재현을 확인했다(2026-09-08)** — "작성 완료 pop 복귀"가 조용한 전체 재조회(같은 ID 교체)에서 "목록 비움 → 로딩 → 첫 페이지 재로드"로 바뀌어 LazyVStack이 아예 새로 서는데, 옛 결정론 조건 그대로(피드 정확히 3개 로드·셀 3개 실현 → 플로팅 작성 → 완료 pop 복귀)를 iPhone 17 Pro 시뮬레이터(iOS 26.5)에서 **3회 반복해 3회 모두 정상**(스냅샷 즉시 settle·스크롤 반응·프로세스 CPU 0%)이었다. 예전 3/3 재현과 대칭인 3/3 미재현이라 이 화면의 주 트리거는 해소로 판정 — 단 근본 원인(몰입형 헤더+스티키 탭+LazyVStack+GeometryReader 비수렴) 자체를 고친 건 아니어서, "피드 목록이 같은 ID로 제자리 교체되는" 새 코드를 이 화면에 다시 넣으면 되살아날 수 있다(그때 이 항목을 다시 볼 것).
- ⚠️ **`feedsTask` 슬롯 불변식이 #256부터 SosoFeed와 같아졌다** — 취소된 `loadFeeds`의 defer는 **아무것도 정리하지 않는다**(`if !Task.isCancelled`). 정리하면 취소+즉시 재대입하는 `reloadFeedsForCreatedFeed`의 새 슬롯·로딩 표시를 옛 로드가 지운다. 그래서 **재대입 없이 취소만 하는 호출자(`deleteFeed`)는 취소 직후 `feedsTask = nil`·`isLoadingFeeds = false`를 스스로 되돌려야** 한다 — 예전엔 defer가 무조건 정리해 cancel만 해도 됐다(이 대칭을 깨면 슬롯이 non-nil로 굳어 이후 로드가 영구 차단되거나, 반대로 새 로드 표시가 지워진다). 더보기(`loadMoreFeeds`)는 여전히 `feedsTask == nil` 가드로 진 쪽이 조용히 드롭된다(스크롤 재실현으로 복구 — "밀린 요청 기억" 방어를 되살리지 말 것, 서재 #195에서 더 나쁜 결함으로 판명). 재진입 셀 동기화는 별도 슬롯(`cellSyncTask`)이라 이 경합 대상이 아니다.
  - ⚠️ **`syncVisitedFeeds`의 슬롯 정리는 defer가 아니라 루프 끝 명시 정리 + 재귀 drain이다**(#256 리뷰,
    `SosoFeedViewModel`과 동일 패턴 — 정본은 [FeedFeature](../FeedFeature/CLAUDE.md) 같은 항목): 도는 동안
    새로 쌓인 pending을 즉시 이어 소비하려 `cellSyncTask = nil` 후 자기 재귀를 부르는데, 이 정리를 defer로
    되돌리면 재귀가 대입한 다음 태스크를 defer가 도로 지워 그 동기화가 유실된다.

- 대응 `NovelDetailDomain`이 없다 — UseCase는 `NovelDomain`/`FeedDomain` 것을 주입받는다. `new-module` 기본 추론(`domain(.<같은이름>)`)과 다른 지점.
- **`state.novel`을 `state.information.novel`과 분리 보유** — `NovelInformation.novel`이 `let`이라 관심 토글(mutating)을 반영할 수 없어서다. 헤더/관심 버튼은 `state.novel`을 읽는다.
- **헤더 메타 줄(장르·연재상태·작가)은 작가만 개별 밑줄 버튼이라 단일 `Text`로 못 합치고 `HStack`으로 분해**(`NovelDetailHeaderView.metaRow`) — 앞부분(`nonAuthorMetaText`=장르·연재상태)은 한 `Text`, 작가는 이름마다 `Button`, 구분자(`  ·  `/`, `)는 **비탭 `Text`**. 작가 `Text`엔 `.underline()`을 **raw Text에 먼저** 걸고 `applyWSSFont`를 뒤에 붙여야 밑줄이 렌더된다(순서 반대면 무증상 실패 — [[DesignSystem]] 주의사항 참고). 탭 영역은 작가 글자에만 국한(구분자 제외)됨을 diagnostic 배경으로 실측 확인.
- **작품 소개 펼침/접힘(`NovelDetailInfoTab.descriptionSection`)은 `lineLimit`을 애니메이션하지 않는다** — `.lineLimit(펼침 ? nil : 3)`을 `.animation(value:)`으로 감싸면 접을 때 4번째 줄 이하가 뚝 사라져 부자연스럽다(#221에서 실제 지적). [[KeywordFeature]] 카테고리 접기(`SearchKeywordView`)와 동일하게 **텍스트는 늘 전문(`lineLimit(nil)`)을 그린 채 `.frame(height: 펼침 ? nil : 접힘높이, alignment: .top)` + `.clipped()`로 프레임 높이만 애니메이션**하고, 토글은 `.animation(value:)`이 아니라 `withAnimation(.easeInOut(0.25))`으로 상태 변경을 감싼다(chevron 회전도 같은 트랜잭션에서 함께 움직임). 접힘높이(3줄)는 Dynamic Type에 따라 달라 고정하지 않고 **숨은 `lineLimit(3)` 사본(`descriptionHeightProbe`)을 GeometryReader로 실측**한다 — `@State collapsedDescriptionHeight` 초기값 67.5(= body2 줄높이 22.5×3)는 첫 프레임 깜빡임 방지 seed일 뿐, `onAppear`/`onChange`가 곧 실측값으로 덮는다(소개글이 재진입 갱신 등으로 바뀌면 다시 잡음). 짧은 글·아주 긴 글, 펼침·접힘 양방향 iPhone SE 실측 확인.
- **몰입형 헤더 = 시스템 네비바 숨김**(`.toolbar(.hidden)`) + 커스텀 고정 오버레이. `icNavigateLeft`/`icAnnouncement`/`icThreedotsVertical` 에셋은 **원색이 연회색(wssGray100)이라 밝은 배경에서 안 보임** → `renderingMode(.template)`로 색을 입혀야 한다.
  - ⚠️ **네비바를 숨기면 밀어서 뒤로가기(`interactivePopGestureRecognizer`)까지 iOS가 함께 꺼버린다** — 뒤로가기가 버튼으로만 되던 이유. WSSComponent의 **`.enableSwipeBack()`** 이 되살린다. 이 화면에도 자체 `SwipeBackEnabler` 복제본이 있었으나 `LibraryFeature` 복제본과 갈라져(이쪽엔 delegate 반납이 없었다) 사고를 만들어 #166에서 공용으로 통합했다 — **다시 화면 안으로 복제하지 말 것.** delegate 수명이 왜 함정인지는 [WSSComponent](../../UI/WSSComponent/CLAUDE.md)의 같은 항목이 정본.
    - ⚠️ **이 제스처는 시뮬레이터 자동화로 검증할 수 없다** — XcodeBuildMCP `gesture(swipe-from-left-edge)`는 화면 가장자리 pan을 트리거하지 못하고(delegate의 `shouldBegin`이 아예 안 불림), CGEvent로 HID 마우스를 주입하는 우회로도 손쉬운 사용 권한이 없어 막힌다(탭조차 전달 안 됨). **사람이 직접 밀어서 확인**해야 한다.
    - 참고: SwiftUI 뷰는 hosting VC의 child라 **superview 체인만으론 뷰컨트롤러에 못 닿는다** — 그래서 `enableSwipeBack`은 `next` responder 체인을 탄다.
- **스크롤 반응형 네비 타이틀**: 조금이라도 스크롤되면 커스텀 네비바에 작품 제목 + 흰 배경을 표시한다(`showNavTitle = scrollOffsetY < -1`). ⚠️ **전환 애니메이션은 사용자 선호로 제거돼 즉시 뜬다**(#244 후속 — `showNavTitle`에 걸었던 `.animation`을 걷어냄, 정본 [WSSComponent](../../UI/WSSComponent/CLAUDE.md), 되살리지 말 것). iOS 17이라 `onScrollGeometryChange`(18+)는 못 쓴다. **구현·함정(이 조합이 핵심 — 개별로 접근하면 다 실패):**
  - **오프셋 측정은 `GeometryReader` 안에서 `onChange`로 `@State`(`scrollOffsetY`)를 직접 쓴다.** `PreferenceKey`+`onPreferenceChange`를 쓰지 말 것 — ⚠️ **(1) ScrollView는 preference를 바깥 조상으로 안 올려보낸다**(reader를 ScrollView 밖 `content`에 붙이면 값이 안 옴), **(2) 이 SDK에선 `onPreferenceChange`→`@State` 갱신 자체가 안 먹는다**(reader를 ScrollView에 직접 붙여도 상수조차 전달 실패). 이 둘 때문에 preference 경로는 전멸한다. 좌표는 ScrollView의 named coordinate space(`scrollSpaceName`) 기준(`.global`은 스크롤 중 갱신이 안 옴).
  - **투명 네비바라 타이틀엔 함께 페이드인하는 흰 배경이 필수** — 없으면 스크롤되는 본문과 겹쳐 안 읽힌다(뒤로가기/더보기 버튼도 이 배경 덕에 가독). 이 배경은 상태바까지 덮어야 하는데, **안전영역 높이를 읽거나 네비바 높이(44)를 더하지 말 것** — 커스텀 상단 바는 **ZStack 자식이면 이미 안전영역 상단에 붙는다**(UIKit `top.equalTo(safeAreaLayoutGuide)`와 동일, 계산 0). 위로 뚫고 나가야 하는 건 **배경뿐**이고, 그건 네비바의 `.background(Color.wssWhite ... .ignoresSafeArea(edges: .top))`가 알아서 화면 끝까지 확장한다(노치·다이나믹 아일랜드 무관, iPhone SE 20pt / 16 Pro 59pt 실측 확인).
    - ⚠️ `.background`는 **`padding` 뒤에** 붙여야 좌우 끝까지 덮는다(앞에 두면 좌우 여백이 뚫린다).
    - ⚠️ 배경 `Color`의 히트테스트는 **표시 상태와 묶어 `.allowsHitTesting(showNavTitle)`** — 투명일 땐(rest, 히어로 위) 바 영역에서 시작하는 드래그가 스크롤로 넘어가야 하고(Color는 투명해도 hit-test 대상이라 켜두면 스크롤이 안 된다), 흰 배경이 콘텐츠를 덮는 동안엔 배경이 터치를 소비해야 한다 — 상시 `false`로 두면 바에 가려 안 보이는 셀·버튼이 바 위 탭에 반응하는 **탭 관통**이 생긴다(2026-09-09 사용자 리포트로 발견, `CollectionDetailView`도 동일 수정). **감수한 손실**: 솔리드 구간엔 바 영역에서 시작한 드래그로 스크롤할 수 없다 — 의도한 트레이드오프라 "바 위 스크롤이 안 된다"를 이유로 되돌리지 말 것(관통 재발).
    - ⚠️ (여전히 유효) **ZStack 안에 중첩된 `GeometryReader`의 `safeAreaInsets.top`은 0으로 보고**된다(상위가 이미 소비) — 안전영역을 *읽어야만* 하는 상황이 오면 루트 `GeometryReader`를 써야 한다. `ignoresSafeArea`는 별개 메커니즘이라 중첩돼도 정상 동작한다.
- **스티키 탭바(정보/피드)**: 스크롤로 탭바가 커스텀 네비바 하단에 닿으면 그 아래에 고정돼 보인다. **`LazyVStack(pinnedViews:)`를 쓰지 말 것** — pin 위치는 ScrollView의 content inset 상단인데 이 화면은 몰입형이라 `.ignoresSafeArea(edges: .top)`이 걸려 있어 **탭바가 상태바 밑(화면 최상단)에 붙어** 네비바와 겹친다. 대신 **오버레이 2벌 방식**: 스크롤 콘텐츠 안 "원본" 탭바는 자리만 유지(스티키 전환 시 콘텐츠 점프 방지)하고, 네비바와 **같은 VStack**에 탭바를 하나 더 그려 조건부로 띄운다(네비바 "바로 아래"가 레이아웃으로 보장 → 스티키 y 계산 불필요).
  - 임계선(네비바 하단 y)은 **안전영역을 읽거나 44를 더하지 않는다** — 이미 `ignoresSafeArea`로 상태바까지 확장된 **네비바 배경의 실측 높이**가 곧 `안전영역 top + 네비바 높이`다. 그래서 배경 `Color`를 `GeometryReader`로 감싸고(**`ignoresSafeArea`는 GeometryReader 쪽에** 붙여야 확장분이 `proxy.size.height`에 잡힌다) 그 높이를 쓴다.
  - 원본 탭바 위치(`tabBarMinY`)는 네비 타이틀과 **같은 방식**으로 잰다(named coordinate space + `GeometryReader` 안 `onChange`). 두 좌표 모두 화면 좌상단 기준이라 그대로 비교(`tabBarMinY <= navigationBarBottomY`).
  - ⚠️ 스티키 탭바는 ScrollView **바깥** 오버레이라 **그 위에서 드래그해도 스크롤되지 않는다**(탭 전환은 정상). 탭바가 얇아 실사용 영향은 작지만, 스크롤이 필요해지면 제스처를 스크롤뷰로 전달하는 별도 처리가 필요하다.
  - **탭 전환 시 화면 튐 → 탭 콘텐츠에 `.frame(minHeight: tabContentMinHeight, alignment: .top)`으로 해결.** 짧은 탭(피드 몇 개)으로 바뀌면 `contentSize`가 줄어 UIScrollView가 `contentOffset`을 스크롤 가능한 최대치로 되돌린다(클램프) → 화면이 위로 튄다. 최소 높이를 **"스티키 상태에서 탭바 아래 남는 화면 영역"**(`스크롤뷰 높이 - 네비바 하단 y - 탭바 높이`)만큼 주면 어떤 탭이든 스티키 지점까지의 스크롤 여유가 남아 클램프가 없다. 피드는 **지연 로드**라 로딩 중 잠깐 비는 순간에도 클램프가 걸리므로 이 최소 높이가 특히 필요하다.
    - ⚠️ 뷰포트 높이를 재는 `GeometryReader`에도 **`ignoresSafeArea(edges: .top)`을 걸어야 한다** — ScrollView는 이미 상태바까지 확장돼 있는데 background의 GeometryReader는 그냥 두면 안전영역 **안쪽** 높이를 보고한다. 그러면 최소 높이가 **딱 안전영역 top만큼**(SE 20pt) 모자라 탭 전환 시 그만큼 덜 붙는다(증상이 미묘해 원인 찾기 어렵다).
- **헤더 상단 인셋은 디자인 고정값(99)이 아니라 실측 `navigationBarBottomY`를 넘겨 쓴다** — 99 = 상태바 54 + 네비 44로, 안전영역이 다른 기기(SE 20 / 16 Pro 59)에선 표지가 네비바에서 뜨거나 겹친다. ⚠️ **헤더 배경(backdrop) 높이도 같은 인셋에 묶어야 한다**(`topInset + 표지 217 + 14`) — 디자인의 330은 "표지 아래 14pt에서 회색으로 전환"을 뜻하는 파생값이라, 표지만 인셋을 따라가고 배경을 330으로 고정하면 안전영역이 작은 기기에서 **제목이 회색이 아닌 블러 보라 배경 위로 올라온다**.
- **표지 우하단 장르 코너 뱃지 = `icGenreBackground`(흰 코너 삼각형 71pt) 우하단에 `genre.iconImage`(GenreIcon 방패형)를 `trailing 4 / bottom 5` 인셋으로 얹음.** V1(UIKit) 레이아웃 그대로. 주의: 아이콘은 배경을 꽉 채우지 않고 **32pt**로 코너에 작게 — 71pt로 키우면 틀림. 겹칠 아이콘은 `markImage`(GenreMark)가 **아니다**(헷갈리기 쉬움).
- **Demo 실서버 모드는 토글 시 `syncKeywords()`를 직접 호출**한다 — 작품 상세의 키워드 매핑이 파일 캐시(keywords.json)만 읽는데, 실제 앱에선 App(DI)이 시작 시 채울 캐시를 Demo는 스스로 채워야 해서다. 안 부르면 캐시 없는 시뮬레이터에서 키워드 섹션이 통째로 빈다(에러 없이 조용히).
- **플랫폼 아이콘 URL은 래스터(png)여야 한다** — 표지가 아니라 `WSSNovelCoverImage`가 안 맞아 raw `WSSAsyncImage`로 캐시하는데(#244, 반복 렌더 시 placeholder 번쩍임 방지), 이것도 결국 `UIImage` 기반이라 **런타임 다운로드 SVG를 디코딩 못 해** SVG URL이면 조용히 placeholder(회색)만 남는다(에셋 카탈로그 번들 SVG만 지원되는 iOS 제약).
- 빈 상태는 `NovelDetailEmptyView`(화면 전용) — WSSComponent `WSSEmptyView`는 검색 빈 상태 전용(고정 문구+버튼 필수)이라 재사용 불가.
- **피드 셀 인터랙션**: 셀 탭=피드 상세 콜백, 프로필 영역(이미지+닉네임) 탭=유저 프로필 콜백(**내 글이면 차단** — `isMyFeed`), 좋아요=엔티티 `TotalFeed.toggleLike()` 낙관 반영+실패 롤백(셀별 병행 허용, 같은 셀 연타만 가드), threedots=셀 드롭다운(**내 글: 수정하기 콜백·삭제하기, 남의 글: 신고 2종 빨강** — Figma 6773-26280/26272). 드롭다운은 화면 레벨 오버레이로 띄우고 앵커는 **셀 y 실측**(네비 타이틀과 같은 스크롤 좌표공간 방식) + threedots 오프셋(52)으로 계산, 하단 셀에선 화면 안에 다 보이게 클램프. ⚠️ 앵커가 화면 최상단(상태바 포함) 기준이라 **오버레이 ZStack에 `ignoresSafeArea(edges: .top)` 필수** — 빼면 메뉴가 안전영역 높이만큼 내려앉는다.
  - ⚠️ **프로필 탭이 탈퇴 유저(`BaseDomain.Author.accessibleUserId == nil`)를 가리키면 이동 대신
    `WSSToastType.unknownUser` 토스트를 띄운다**(#197 후속, 2026-08-28) — `NovelDetailFeedTab`이
    `feed.author.accessibleUserId`로 판정해 `onUnavailableUserProfileTapped()`(새 콜백)를 부르고,
    `NovelDetailView`가 그걸 `viewModel.handle(.userProfileUnavailable)`로 연결해
    `DetailToast.unavailableUser`를 세운다. `-1` 리터럴을 여기서 다시 비교하지 말 것 — `SosoFeedView`/
    `FeedDetailView`(`FeedFeature/CLAUDE.md`)와 같은 Domain API를 공유한다.
  - 좋아요 버튼은 `feedCell`에서 `WSSFeadView`의 `likeButtonTapped`로 `onToggleLike(feed.feedId)`를 넘긴다.
- **"수정하기"(내 글 드롭다운)는 목록 항목(`TotalFeed`)의 `FeedID`만 `.editFeed` 라우트로 넘긴다** — 데이터 로드는 이 화면이 아니라 App이 조립하는 수정 화면(`FeedFeature`의 `CreateFeedView`) 자신이 한다(`FeedFeature/CLAUDE.md`의 `CreateFeedViewModel` 항목 참고). 이 화면 쪽엔 준비 상태·로딩 오버레이가 없다 — 탭하면 바로 App이 화면을 전환한다(#197, 빠른 전환 우선).
- **피드 삭제/신고는 2단 알럿 하나의 의미값(`FeedAlert`)으로 관리** — 삭제는 확인 알럿 → `DeleteFeedUseCase` → 목록 제거 + **상세 재로드**(헤더 피드 수 등 집계 동기화, 성공 토스트 없음 — 디자인에 없음). 신고는 확인 알럿 → SocialDomain UseCase → **접수 완료 알럿으로 전환**(문구가 종류별로 달라 완료 케이스 분리). 알럿 타입·버튼 매핑(WSSAlertType 5종)은 View가 한다.
  ⚠️ **이미 신고한 피드에 같은 종류를 다시 신고하면(서버 `REPORT-002` → `RepositoryError.alreadyReported`) 완료
  알럿 대신 "이미 신고한 피드예요" 토스트로 안내한다**(#255 QA — `DetailToast.reportFeedAlreadyReported` →
  `WSSToastType.alreadyReportedFeed`, `reportFeedFailed`와 분리). `UserPageFeature`/`FeedFeature`도 같은 서버
  코드를 동일한 방식(대상별 토스트 문구 분리)으로 처리한다 — 이 화면만 다른 표현으로 갈라지지 않게 유지할 것.
- **화면 드롭다운(오류 제보/평가 삭제)**: 오류 제보는 노션 문의 페이지를 외부 브라우저로 연다(`BaseDomain.AppURL.errorReport`, #165에서 화면 전용 상수에서 앱 전역 카탈로그로 이관). 평가 삭제는 알럿 확인 후 `DeleteNovelReviewUseCase`(NovelReviewDomain) → **성공 시 상세 재로드**(키워드·읽기 상태 집계가 함께 바뀌므로 화면 데이터를 서버와 재동기화). 삭제할 평가가 없으면 VM이 무시(관심 토글 no-op과 같은 정책).
- 유저 평가 없음 셀렉터와 있음 상태바는 같은 3분할 레이아웃 — **둘 다 상태별 개별 진입(탭한 상태를 seed)**. 있음은 추가로 박스의 칩·여백을 탭하면 현재 상태로 진입한다(상태 `Button`이 hit-test 우선이라 바깥 `onTapGesture`와 공존 — 중첩 Button은 불안정해 피함).
- **대형 표지 오버레이(표지 탭)**: dim(`wssBlack60`)의 `onTapGesture`와 확대 표지를 ZStack **형제**로 두면 표지 위 탭은 자연히 무시된다(제스처는 형제 뷰에 안 닿음 — V1의 표지 탭 no-op과 동일 동작, 별도 처리 불필요). 확대 크기는 `scaledToFit` + 패딩(가로 20 / 세로 60 = X 버튼 44 + 여유)이 V1의 "두 여백 중 먼저 걸리는 기준" 비율 분기 계산을 대체한다.
  - ⚠️ **오버레이 안에서 `AsyncImage`를 쓰지 말 것** — URLCache 캐시 히트여도 **새 인스턴스는 `.empty` phase부터 시작**해 placeholder가 한 프레임 이상 번쩍이고, 오버레이는 열 때마다 뷰가 재생성되므로 매번 반복된다. 대신 화면 로드 시 `URLSession.shared`(URLCache 공유 — 헤더가 이미 받은 응답이면 재다운로드 없음)로 `UIImage`를 **prefetch해 동기로 그린다**(영상 프레임 검증: 오버레이 첫 프레임부터 실제 표지).
  - clip·그림자는 컨테이너가 아니라 **핏된 이미지 자신에** 걸 것 — 컨테이너 크기가 핏 결과와 어긋나면 이미지 주변 탭이 dim에 안 닿는 dead zone 위험. X 아이콘 `icCancelModal`도 원색이 회색(#52515F)이라 dim 위에선 template + 흰색 틴트 필요(네비바 아이콘과 같은 함정).
- **상단 오버스크롤(당겨서 내림)은 stretch 헤더로 받는다**(`NovelDetailHeaderView.backdrop`, #221). 예전엔 `TopBounceDisabler`(UIViewRepresentable)가 조상 `UIScrollView`를 찾아 `contentOffset` KVO로 `y<0`을 0으로 클램프해 **상단 바운스를 막았으나**, 그 KVO가 mode 6 승격의 유일한 잔여였다(아래). 대신 #200 컬렉션 상세식 **순수 SwiftUI stretch**로 교체 — backdrop의 `GeometryReader`가 `scrollSpaceName` 좌표공간에서 `minY`를 재 `stretch = max(0, minY)`만큼 블러 레이어를 `scaleEffect(anchor: .top)` + `offset(y: -stretch)`로 확대해 빈 영역을 메운다. `zoomScale = 1 + stretch/backdropHeight`라 하단 경계(gray50 접점)는 **고정**되고 위쪽으로만 번진다(`CollectionDetailView.heroSection`과 같은 계산). 이 stretch는 정지 상태(minY=0)에서 identity라 rest 렌더는 그대로다.
  - ✅ **이 모듈은 Swift 6 mode 6이다(#221).** 한때 위 KVO의 main-actor 격리 경고 3건이 mode 6 승격의 유일한 잔여였고, `MainActor.assumeIsolated` 래핑은 **경고는 없애지만 상단 클램프가 시각적으로 깨졌다**(#219 실측, 되돌림). #221에서 KVO를 stretch 헤더로 걷어내 근본 해결 → `Project.swift`가 기본값(`enableSwift6: true`)으로 편입. 교훈은 유효하다: **UIScrollView/KVO 브리징을 `assumeIsolated`로 블라인드 처리하지 말 것**(→ [[verify-dont-assume-runtime]]).
  - ⚠️ **mode 6가 드러낸 숨은 결함**: 알림 시트 VM(`NovelNotificationSettingSheetViewModel.sync`)이 `NovelNotificationSetting`을 `updateNotificationSettingUseCase.execute`로 넘길 때 actor 경계를 넘는다 — 그 엔티티에 `Sendable`이 빠져 있으면 mode 6에서 "sending risks data races" **error**다(#189가 형제 엔티티와 달리 Sendable을 빠뜨렸던 것을 #221 승격이 잡음). 도메인 Entity가 UseCase 인자로 actor를 건너면 반드시 Sendable이어야 한다.
- **`NovelNotificationSettingSheetViewModel`의 `isSyncing`은 반드시 액션 핸들러(동기 코드)에서 Task 스폰 *전에* 세운다.** `sync()`(비동기 함수) 안에서 세우면, 토글 두 개가 Task 스케줄링 틈새(같은 런루프 틱)에 연달아 들어왔을 때 **둘 다 `guard !state.isSyncing`을 통과**해 PUT이 겹쳐 나간다 — `NovelDetailViewModel`의 `isSyncingInterest = true` → `Task { }` 순서와 같은 이유(리뷰에서 실제 발견).
- **이 시트는 명시적 닫기 버튼이 없다**(스와이프로만 닫힘) — 그래서 화면 다른 곳의 `requestClose` 액션 + `isClosing` 패턴을 못 쓰고, 대신 View의 **`.onDisappear`가 `.disappear` 액션을 발화**해 `isClosing` 세팅 + 진행 중 Task 취소를 대신한다. 닫기 버튼이 없는 서버 호출 화면(시트 등)을 새로 만들 때 이 변형을 참고할 것 — `requestClose`를 억지로 만들 필요 없다.
- **네비바 우측 아이콘 버튼(종·threedots)의 터치영역은 라벨 패딩으로 확장돼 있다** — 종=leading 20/trailing 6, threedots=leading 6/trailing 20, 둘 다 높이 44, 버튼 간 간격 4. threedots의 trailing 20이 라벨 안이라 **디바이스 우측 끝까지 탭이 먹는다**. 아이콘 시각 위치는 확장 전과 동일(아이콘 간 16pt·trailing 20pt — 드롭다운 앵커 `.padding(.trailing, 20)`도 이 시각 위치 기준이라 무관). 우측 클러스터 전체 폭(터치영역 포함)은 50+4+46 = **100pt**이고, 네비 타이틀 대칭 패딩(코드상 leading 94/trailing 100)이 이 값에 묶여 있다 — 버튼 인셋을 바꾸면 같이 갱신할 것.
- **첫 진입 평가 온보딩 오버레이(#221, V1 parity 복원)**: 첫 상세를 **앱 전역 1회**만, 화면을 딤 처리하되
  **평가 상태바 자리만 뚫어**(스포트라이트) 실제 상태바가 밝게 비치게 하고 그 아래 말풍선으로 "평가해보세요"
  힌트를 띄운다. 저장은 `BaseDomain.OnboardingHintUseCase`(`.novelDetailReview`) — VM이 **첫 로드 성공 시에만**
  `hasSeen`이 false면 `state.showReviewOnboarding`을 세우고(재진입 조용한 갱신에선 안 뜸), 닫으면 `markSeen`.
  ⚠️ **구현 함정 4가지**:
  - **스포트라이트는 실제 상태바를 딤에서 뚫는다**(복제본 아님) — `reverseMask`(딤에서 상태바 사각형을
    `destinationOut`으로 빼 그 자리 알파 0). 상태바 프레임은 `NovelDetailReviewSection`이 `scrollSpaceName`
    좌표(= 화면 좌상단 기준, ScrollView가 상태바까지 확장돼서)로 실측해 `onReviewBoxFrameChange`로 올린다.
  - **오버레이 ZStack에 `.ignoresSafeArea()` 필수** — 그래야 오버레이 좌표 원점이 화면 좌상단이 돼 실측
    프레임(scrollSpaceName)과 `.position`/`reverseMask`가 정렬된다. 빼면 안전영역 top만큼 구멍이 어긋난다.
  - **최상단 투명 탭 레이어(`Color.wssBlack.opacity(0.001)`)가 필수** — 구멍(실제 상태바)은 딤이 없어
    그대로 두면 상태바 탭이 **평가 화면으로 새어나간다**. 이 레이어가 어디를 탭하든 먼저 받아 닫기로 돌린다
    (딤·말풍선은 `allowsHitTesting(false)`). iPhone 17 Pro 실측 — 스포트라이트 안 "보는 중"을 탭해도 평가로
    안 가고 오버레이만 닫힘 확인.
  - **`reviewBoxFrame.height > 0`으로 게이트** — 상태바 실측 전(첫 프레임)엔 오버레이를 안 띄운다(엉뚱한 위치에 구멍 방지).
- **스크롤 반응형 네비 타이틀은 화면 정중앙에 오도록 좌우 `.padding`을 대칭(양쪽 다 80pt 기준)으로 맞춘다** — 우측 클러스터(80pt)가 좌측(뒤로가기 44pt + 이 `HStack` 전체에 걸린 `.padding(.leading, 6)` = 화면 기준 실제 50pt)보다 넓어서다. 대칭을 맞추려면 **양쪽 다 더 넓은 쪽(80)을 기준**으로 삼아야 하는데, `Text`의 `.padding(.leading,)`은 이 `.padding(.leading, 6)`으로 이미 6pt만큼 밀린 로컬 좌표 위에서 계산되므로 **코드에는 74를 적는다**(74+6=80). `.padding(.leading, 44)`처럼 뒤로가기 실측값을 그대로 쓰면 좌측 여백이 6pt 부족해 타이틀이 더 넓은 우측으로 밀려 정중앙에서 벗어난다 — 좌우 버튼 폭이 바뀌면 두 값(`leading`은 `-6` 보정 포함, `trailing`은 그대로) 모두 "더 넓은 쪽 폭" 기준으로 다시 맞출 것.
