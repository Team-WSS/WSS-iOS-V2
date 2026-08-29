<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# CollectionFeature

컬렉션(사용자가 작품을 묶어 만드는 목록) 화면. `CollectionDomain`/`CollectionData`(#191)가 먼저 만들어져
있었고, 이 모듈은 그 위에 화면을 얹는 첫 착수(#199, 컬렉션 생성 화면부터).

- 식별자: `ModuleType.feature(.collection)` / 의존: `CollectionDomain`, `SearchDomain`(작품 검색 —
  "작품 추가" 화면), `NovelDomain`(서재 조회 — "서재에서 추가" 화면, 서재 Domain 코드는 별도 모듈이
  아니라 `NovelDomain`에 있다 — `LibraryFeature`와 같은 이유), `BaseDomain`, `DesignSystem`,
  `WSSComponent`, `Logger`
- 진입점 (#201부터 — **화면 간 이동은 전부 App이 조립한다.** "작품 추가"/"서재에서 추가"처럼 다른
  화면의 draft를 채우는 값 선택기까지 포함해 예외 없이 App으로 옮겼다(사용자 확정) — 이 모듈 안에는
  `navigationDestination`이 없다. 화면이 6개라 전부 `makeXxxView`로 이름을 붙였다):
  - `CollectionFeatureFactory.makeCreateCollectionView(createCollectionUseCase:logger:pendingNovelSelection:onAddNovelTapped:onAuthenticationRequired:)` — 생성 전용(`Mode.create` 고정).
  - `CollectionFeatureFactory.makeEditCollectionView(id:updateCollectionUseCase:loadCollectionDetailUseCase:logger:pendingNovelSelection:onAddNovelTapped:onAuthenticationRequired:)` — 수정 전용(`Mode.edit(id)` 고정). `CreateCollectionView`를 수정 모드로 재사용하지만, `Mode`가 `internal`이라 `public` 시그니처에 노출할 수 없어(Swift 접근제어 제약) 생성과 별도 진입점으로 쪼갰다.
  - `CollectionFeatureFactory.makeSearchNovelView(initialSelection:searchNovelUseCase:logger:onConfirm:onLibrarySelectTapped:onAuthenticationRequired:)` — "작품 추가" 화면.
  - `CollectionFeatureFactory.makeMyLibrarySelectView(initialSelection:loadMyLibraryUseCase:logger:onConfirm:onAuthenticationRequired:)` — "서재에서 추가" 화면.
  - `CollectionFeatureFactory.makeCollectionListView(userID:loadCollectionsUseCase:loadLikedCollectionsUseCase:logger:onAuthenticationRequired:onCreateTapped:onCollectionSelected:isOwnCollections:)`
    (`isOwnCollections` 기본값 `true` — `false`면 세그먼트 탭·"컬렉션 만들기"를 숨기고 "내 컬렉션"
    콘텐츠만 보여준다, 타유저 프로필 재사용 — 아래 주의사항 참고)
  - `CollectionFeatureFactory.makeCollectionDetailView(id:loadCollectionDetailUseCase:collectionLikeUseCase:deleteCollectionUseCase:logger:onAuthenticationRequired:onNovelTapped:onEditTapped:)`(#201, 컬렉션 상세)
  - **`pendingNovelSelection: Binding<[CollectionNovel]?>`**은 "작품 추가"/"서재에서 추가" 확정 결과를
    생성/수정 화면에 **돌려주는**(return) 1회성 nil→값 채널(`OnboardingFeature`의 확정 신호 패턴과
    동일) — App이 확정 시점에 값을 채우고 그만큼 pop한다(아래 "2단계 pop" 주의사항 참고). 이 방향은
    Binding이 맞다 — 받는 화면(`CreateCollectionView`)이 이미 mount돼 있어 `.onChange`로 값 변화를
    안전하게 관찰할 수 있다.
  - **반대로 `makeSearchNovelView`/`makeMyLibrarySelectView`의 `initialSelection:`(진입 시 채워줄
    선택 스냅샷)은 App이 반드시 `NavigationPath`의 `Destination` payload로 실어 보내야 한다 —
    별도 `@State` 스크래치 변수에 먼저 써두고 `path.append(...)`한 뒤 그 변수를 읽어 destination을
    만드는 방식은 레이스가 있다(#201 실측, 아래 "진입 파라미터는 반드시 path payload로" 주의사항
    참고).** `CollectionNovel`은 이제 `Hashable`이라(#201) `[CollectionNovel]`을 그대로 payload에
    넣을 수 있다.

## 핵심 시나리오

- **`CreateCollectionView`/`CreateCollectionViewModel`은 생성/수정 겸용이다**(`Mode { case create; case
  edit(CollectionID) }`, `FeedFeature.CreateFeedViewModel`과 동일 패턴). 생성은 빈 `CollectionDraft()`로
  시작(로드 없음)하고 `CreateCollectionUseCase`로 제출, 수정은 `CollectionDraft(from: detail)`로 원본을
  편집 가능한 초안으로 되돌려 시작하고 `UpdateCollectionUseCase`로 제출 — 둘 다 성공 시 자기완결
  dismiss(공통 `submitCollection()`이 `mode`로 분기). 폼 UI·검증(`isSubmittable`)·"작품 추가" 2단계
  pop·뒤로가기 확인 알럿(`baselineDraft` 비교)은 두 모드가 완전히 공유한다.
  ⚠️ **수정 진입 시 `initialNovelDisplayInfo`(원본 `detail.novels`를 id로 인덱싱한 딕셔너리)도 함께
  넘겨야 한다** — 그리드는 `draft.novelIDs`가 아니라 이 캐시를 보고 그리므로, 안 채우면 "N/100" 개수
  표시는 맞는데 그리드 셀이 하나도 안 그려진다(실측, `novelListSection` 참고).
- **작품 추가/제거는 `CollectionSearchNovelView`(`makeSearchNovelView`, Factory 노출)에서 이뤄진다** —
  `CreateCollectionView`의 "작품 추가"/"작품 수정" 타일이 `onAddNovelTapped`로 App에 알리면 App이 이
  화면을 push하고, `SearchNovelUseCase`로 검색·다중선택한 뒤 "완료"를 누르면 선택 목록 **전체**가
  `onConfirm` → App의 `pendingNovelSelection` → `.setNovels`로 `draft.novelIDs`를 통째로 교체한다
  (부분 추가/제거 액션 없음 — 화면을 나갈 때 최종 선택 스냅샷만 반영). 검색 중 골라둔 항목은 검색어를
  바꿔도 별도 상태(`selectedNovels`)로 유지된다. 정원(`CollectionDraft.maxNovelCount`=100)이 차면 더
  담기지 않고 `WSSToastType.selectionOverLimit`로 알린다 — **문구는 범용 텍스트("100개까지 선택
  가능해요")를 임시로 쓰는 중**, 기획팀 확정 문구 전달 예정(2026-08-24). 문구가 오면 `WSSToastType`
  텍스트만 교체하면 된다(구조는 이미 확정).
- **검색 결과 무한스크롤** — `SearchFeature.NormalSearchViewModel`과 동일한 정수 `page`(0부터) 방식.
  `LazyVStack` 마지막 행 `onAppear`에서 `.loadMore`를 발화하고, `CollectionSearchNovelViewModel`이
  `hasNextSearchPage`(서버 `Paginated.hasNext`)가 false가 될 때까지 다음 페이지를 이어붙인다.
- **"서재에서 추가"(`CollectionMyLibrarySelectView`, `makeMyLibrarySelectView`, Factory 노출)** —
  `CollectionSearchNovelView`의 "서재에서 추가" 버튼이 `onLibrarySelectTapped`로 App에 알리면 App이
  push. 사용자의 서재를 `LoadMyLibraryUseCase`(필터 없음, `MyLibraryFilter()`
  기본값)로 3열 그리드 조회하며 다중 선택 → "추가"로 확정한다. 데이터 로드는 정수 `page`가 아니라
  `LibraryFeature.LibraryViewModel`과 동일한 **커서 + generation 카운터** 패턴(`LoadMyLibraryUseCase`가
  커서 기반이라서). 선택 상태는 `CollectionSearchNovelView`가 자신의 `selectedNovels`(검색으로 이미
  고른 것)를 `initialSelection`으로 시드해서 넘기므로, 검색으로 고른 것과 서재로 고른 것이 하나의
  배열에서 자연스럽게 합쳐진다(확정 시 별도 병합 로직 불필요). 셀은 `WSSComponent.WSSLibraryGridCell`
  (2026-08 승격, 원본은 `LibraryFeature.LibraryGridCell`) — 처음엔 `LibraryGridCell`이 Feature 로컬
  `internal`이라 import 불가해 로컬 복제본(`CollectionMyLibraryGridCell`)을 새로 만들었으나, 두 화면의
  유일한 차이가 표지 우상단 선택 서클(`icSelectNovelDefault`/`icSelectNovelSelected`, `WSSNovelSelectRow`와
  동일 에셋)뿐임을 확인하고 `isSelected: Bool?`(nil=선택 UI 없음)로 흡수해 공용 컴포넌트로 승격했다 —
  이 레포의 "두 번째 필요 시점에 승격" 관례(`WSSNovelSelectRow`/`WSSPrivateToggleRow`/`WSSNicknameField`
  와 동일) 그대로다. 날짜 포맷도 로컬 복제(`CollectionLibraryDateFormatter`) 대신
  `ReadingPeriod.displayText`(`WSSComponent/Sources/DomainPresentation/`)로 통합됐다 — 자세한 계약은
  [WSSComponent](../../UI/WSSComponent/CLAUDE.md)의 `WSSLibraryGridCell` 항목이 정본.
- **검색 결과 행의 "+ 추가"/"× 삭제" 필 배지는 `WSSComponent.WSSPillBadge`다** — 이번엔 이 화면
  한 곳뿐이지만(2026-08-23), 설정 화면의 작품 알림 해제(다른 미병합 브랜치)가 곧 두 번째로 쓸 예정이라
  두 번째 필요 시점을 기다리지 않고 미리 승격했다(사용자 명시 요청). 자세한 계약은
  [WSSComponent](../../UI/WSSComponent/CLAUDE.md)의 `WSSPillBadge` 항목 참고.
- **컬렉션 목록(`CollectionListView`, Factory 노출)** — "내 컬렉션"/"좋아요한 컬렉션"을 한 화면에서
  세그먼트 탭(`CollectionSegmentedTab`, 로컬)으로 전환. 마이페이지 "컬렉션 N개" 행에서 진입(#200/#201,
  `UserPageFeature`가 콜백만 노출하고 실제 push는 `MypageRootView`가 한다 — 두 Feature는 서로 import
  못 해 App 몫).
  `LoadCollectionsUseCase`(userID 필수)/`LoadLikedCollectionsUseCase`(userID 불필요, 세션 토큰 기준)를
  탭마다 독립된 커서+generation 부기로 lazy 로드한다 — 처음 그 탭을 볼 때만 첫 페이지를 요청하고, 이미
  본 탭은 오갈 때마다 재요청하지 않는다(`CollectionListViewModel`, `CollectionMyLibrarySelectViewModel`의
  패턴을 탭 2개로 확장). "내 컬렉션" 탭에서만 "컬렉션 만들기" 버튼이 보이고, 탭하면 `onCreateTapped`로
  App에 알려 `makeCreateCollectionView`가 push된다 — 그 화면은 성공 콜백이 없는 계약이라(자기완결
  dismiss만) **이 화면은 복귀를 "성공/취소"로 구분하지 않고** `hasAppearedOnce` 플래그로 감지한다(이
  화면의 App 경로엔 자식이 이 화면 하나뿐이라, 최초 `onAppear` 이후의 재발화는 정의상 "그 자식에서
  돌아옴"이다) — 복귀 시 무조건 `.reloadAfterReturn(selectedTab)`으로 그 탭을 다시 로드한다. 카드
  표지 스택은 `CollectionCoverStackView`(로컬) — 마이페이지 미리보기(`UserPageFeature.CollectionSection`,
  대표 표지 1장)와는 시각 패턴이 달라 별개 컴포넌트다. **표지 슬롯은 실제 작품 수(1~5)와 무관하게 항상
  5칸**이다(사용자 확정, 2026-08-21) — `recentNovels`가 5개 미만이면 남는 슬롯을
  `WSSNovelCoverImage(url: nil)`의 기본 표지 폴백으로 채운다("몇 개 들었나"를 표지 개수로 세지 않게
  하려는 의도, 작품 수는 카드 부제 `작품 N`으로만 알린다). 오버플로 배지("+N")는 없다 — Figma 목업의
  숫자 배지는 실제 컴포넌트가 아니라 더미 데이터의 잔재였다(사용자 확정).
- **컬렉션 상세(`CollectionDetailView`, Factory 노출, #201)** — `CollectionListView`의 카드 탭이
  `onCollectionSelected(CollectionID)`로 App에 알리면 App이 push한다(#201부터 로컬
  `.navigationDestination(item:)`이 아니라 App의 `NavigationPath`). 히어로 배경은 `representativeNovelID`로
  `novels` 배열에서 찾은 표지 위에 다크 그라데이션(상단 투명→하단 36% 블랙, `NovelDetailFeature`처럼
  블러는 없음). `LoadCollectionDetailUseCase.execute(id:sortType:)`로 1회 로드(push 화면 — 재진입 시
  재로드 안 함)하고, 정렬 토글(`WSSSortButton`, "최신순"↔"오래된순")은 가드 없이 매번 새로 조회한다.
  좋아요는 `CollectionDetail.toggleLike()` 낙관 반영 + 실패 롤백(`UserPageFeature` 피드 좋아요와 동일
  패턴). 복귀 시 `CollectionListView`는 무조건 그 탭을 재로드한다(위 `hasAppearedOnce`/`reloadAfterReturn`
  경로 — 좋아요·삭제로 카드가 바뀌었을 수 있어서, `CreateCollectionView` 복귀와 동일 판단).

## 화면 동작 계약

- **뒤로가기(취소)**: 변경 사항이 없으면 바로 닫히고, 있으면 확인 알럿을 띄운다 — `NovelReviewFeature`/
  `FeedFeature`의 "그만 작성" 패턴과 동일(사용자 확정, #199). 생성/수정 겸용 화면이라 **알럿 타이틀만
  모드에 따라 갈린다**(사용자 확정) — 생성은 "컬렉션 생성을 그만하시겠어요?"(`WSSAlertType.stopWritingCollection`),
  수정은 "컬렉션 수정을 그만하시겠어요?"(`.stopEditingCollection`). 버튼 문구("그만하기"/"계속 작성")는
  두 모드 공통. 기준선은 생성은 빈 `CollectionDraft()`, 수정은 `CollectionDraft(from: detail)`(원본 값).
- **작품 카드(표지 이미지) 셀 전체를 탭하면 그 작품이 대표로 전환**된다(`CollectionDraft.setRepresentativeNovel`)
  — 처음엔 우상단 "대표" 배지만 탭 대상이었으나, 배지만으론 탭 영역이 좁다는 사용자 피드백으로 **셀
  전체**로 넓혔다(#199). 배지는 순수 표시용(대표 여부 뱃지)이라 더는 별도 `Button`이 아니다 — 커버
  이미지를 감싸는 `Button` 하나가 셀 전체 탭을 받는다(중첩 `Button` 금지 — `WSSComponent/CLAUDE.md`).
  제거(삭제)는 이 화면 범위가 아니라 `CollectionSearchNovelView`("작품 추가/수정" 화면, 그 안의
  "서재에서 추가"도 포함)에서만 가능하다 — 그 화면의 작품 행을 다시 탭해 선택 해제하고 "완료"/"추가"로
  확정하면 이 그리드에서도 빠진다.
  대표를 한 번도 안 골라도 제출은 된다 — `effectiveRepresentativeNovelID`가 표시 순서 첫 작품으로
  대신한다(도메인 계약, `CollectionDomain/CLAUDE.md` 참고).
- **"완료" 버튼 활성화 기준은 `draft.isSubmittable`**(이름 비어있지 않음 && 작품 1개 이상)이다 — Figma
  3프레임 모두 "완료" 텍스트가 비활성 회색으로 보이지만(작품까지 채운 프레임도 마찬가지), 이는 목업이
  실제 버튼 상태를 반영하지 않은 것으로 보고 도메인 규칙을 그대로 따른다.
  ⚠️ **수정 모드에서는 `isSubmittable`을 만족해도 원본과 달라진 게 없으면(`!hasUnsavedChanges`)
  추가로 비활성화한다**(사용자 확정) — 뒤로가기 확인 알럿과 같은 `hasUnsavedChanges` 비교를 재사용한다.
  생성 모드는 이 조건이 없다(원래 기준만 본다).
- "작품 추가" 타일 아이콘은 신규 에셋이 아니라 기존 `WSSImage.icBookRegister`를 재사용한다 — 그 SVG의
  내부 레이어명이 Figma 원본과 동일한 `mdi:book-plus-outline`이라 이미 같은 아이콘이 들어있었다.
- **"서재에서 추가" 화면("추가" 버튼) 확정 후 `CreateCollectionView`까지 2단계 pop이 정본으로 확정됐다**
  (기획팀 확인, 2026-08-23) — `CollectionSearchNovelView`(작품 검색 화면)로 1단계만 pop하는 대안은
  채택되지 않았다. 자세한 구현은 아래 주의사항 "2단계 pop" 항목 참고.
- **컬렉션 목록의 두 탭은 빈 상태(`CollectionListView.emptySection(for:)`) 모양이 서로 다르고, 확정
  정도도 다르다(사용자 확정, 2026-08-25)** — "내 컬렉션" 탭은 안내 일러스트·문구 없이 **"컬렉션
  만들기" 버튼만** 보여준다(있는 상태 목록 위 버튼과 같은 자리). "좋아요한 컬렉션" 탭은 아직 기획
  확정 전이라 기존 기본값(`WSSImage.imgEmpty` + 안내 문구, CTA 없음)을 그대로 둔 상태 — 나중에 두 탭이
  같은 모양으로 정해지더라도 이 분기를 성급히 하나로 합치지 말 것.
- ⚠️ **컬렉션 목록(#200) 시각 디테일 중 Figma 확인 없이 기본값으로 구현한 것들** — 실측·디자인 재확인
  전까지 이 기본값을 정본으로 삼는다:
  - "좋아요한 컬렉션" 탭 빈 상태 카피("아직 좋아요한 컬렉션이 없어요")는 Figma에 데이터 있는 상태만
    있어 새로 지었다. CTA 없음(`LibraryFeature`의 "타유저 서재" 빈 상태와 동일 판단).
  - 탭 라벨은 Figma 원문 "내 컬랙션"(오탈자로 추정) 대신 표준 표기 "내 컬렉션"을 썼다.
  - 페이지 크기(`size`)는 서버 권장값이 없어 20으로 고정(컬렉션 도메인 공통 — `LoadCollectionsUseCase`/
    `LoadLikedCollectionsUseCase` 둘 다).
- **컬렉션 상세(#201) — 사용자 확정 사항**:
  - 우상단 더보기(`icThreedots`)는 `detail.isMine == true`일 때만 노출, 항목은 "컬렉션 수정"/"컬렉션
    삭제". 하단 버튼 둘째 슬롯은 `detail.isPrivate`로 갈린다 — `true`면 "나만 보는 컬렉션" 비활성
    배지, `false`면 "공유하기" 버튼(비공개 컬렉션은 소유자만 볼 수 있어 `isPrivate`와 `isMine`이 실질
    동치라 이 둘을 따로 판단할 필요가 없다 — `CollectionDomain/CLAUDE.md`).
  - **작품 카드 탭은 `onNovelTapped(NovelID)` 콜백까지 뚫려 있다** — `NovelDetailFeature`로 가야 하지만
    Feature 모듈끼리 서로 import 못 해 이 화면이 직접 만들 수 없다. `NovelDetailFeature.onAuthorTapped`와
    동일하게 VM을 거치지 않고 View가 탭 즉시 호출하고, `CollectionFeatureFactory`까지 그대로 관통시켰다.
    **`MypageRootView`가 이 콜백을 받아 `NovelDetailAssembly`로 push한다**(#201, `docs/TODO.md` 9번
    해소) — 다른 탭(`LibraryRootView` 등)과 동일하게 작품 상세가 다시 여는 리뷰·피드 작성·피드 상세·
    유저 프로필·일반 검색까지 그 서브트리 전체를 `MypageRootView`도 갖는다.
  - **"공유하기"는 카카오 공유 카드 하나다 — 카카오톡이 있으면 카카오톡 앱, 없으면 카카오 웹 공유(Safari).
    시스템 공유 시트는 쓰지 않는다**(#228, 사용자 확정 2026-08-29). 목표가 "받은 사람이 카톡에서 탭해 앱의 이
    화면으로 들어오는 것"인데, 커스텀 스킴(`websoso://…`)을 텍스트로 보내면 **카카오톡이 링크로 인식하지 않아**
    수신자가 진입할 수 없었다(실기기 실측) — 그래서 처음 폐기했던 카카오 SDK(`KakaoSDKShare`/`KakaoSDKTemplate`)를
    다시 들였고, 같은 이유로 시스템 공유 시트(문자·복사)도 걷어냈다(거기로 나가는 커스텀 스킴 링크는 어디서도
    탭이 안 돼 무의미 — Universal Link가 생기면 그때 의미 있는 시트로 다시 검토, `docs/TODO.md` 8절).
    - 카드(`CollectionKakaoShare`, `@MainActor enum`): `FeedTemplate` = 제목(`name`) + 설명(`description`,
      없으면 "작품 N개") + 대표 표지(`heroImageURL`, **옵셔널이라 표지 없으면 이미지 없는 카드** — 기본 이미지
      URL 불필요) + "앱에서 보기" 버튼. 버튼·본문 `Link`는 `webUrl` 없이 `iosExecutionParams`/
      `androidExecutionParams`에 `DeepLink.kakaoExecutionParameters`(`collectionId={id}`)만 싣는다 → 받는 앱엔
      `kakao{APP_KEY}://kakaolink?collectionId={id}`로 도착하고 App `onOpenURL`이 `DeepLink(url:)`로 푼다.
      앱 미설치자는 카카오가 App Store로 보낸다(카카오 콘솔 iOS 플랫폼에 Bundle ID·App Store ID 등록 필요 —
      Demo 번들 `kr.websoso.app.CollectionFeatureDemo`는 등록돼 있지 않으면 템플릿 검증에서 거부될 수 있다).
    - 카카오톡이 있으면 `ShareApi.shared.shareDefault`(템플릿 서버 검증)가 돌려준 `kakaolink://send?…` URL을,
      없으면 `ShareApi.shared.makeDefaultUrl`(로컬 조립, 서버 검증 없음)의 카카오 웹 공유 URL을
      `UIApplication.shared.open`으로 연다 — 카카오톡의 받는 사람 선택 화면 또는 Safari의 카카오 웹 공유가 뜨는
      **여기까지가 성공**이고 실제 전송 여부는 알 수 없다(카카오 안의 일). 실패는 사용자 액션 실패라
      토스트(`isShareErrorToastPresented`, View 로컬 — 공유는 VM을 안 거친다).
    - ⚠️ **카카오톡 설치 판정(`ShareApi.isKakaoTalkSharingAvailable()`)은 `canOpenURL("kakaolink://")`라
      `Info.plist`의 `LSApplicationQueriesSchemes`에 `kakaolink`가 없으면 카카오톡이 깔려 있어도 항상 false**
      (→ 웹 공유로만 나간다). App `Support/Info.plist`와 `ModuleInfoPlist.featureDemo` 둘 다 등록돼 있다.
      시뮬레이터엔 카카오톡이 없어 **앱 경로는 실기기에서만 확인 가능**(시뮬레이터는 항상 웹 공유).
    - SDK는 `KakaoSDK.initSDK(appKey:)`가 먼저 불려 있어야 하고 — App은 `WSSIOSV2App.init`, Demo는
      `CollectionFeatureDemoApp.init`(`NetworkingConfig.kakaoAppKey`) — **호출 앱의 `Info.plist`에
      `CFBundleShortVersionString`이 있어야 한다**(SDK가 `appver` 필수 파라미터로 보냄, 없으면 카카오톡이
      "Core parameter(s) missing"으로 거부 — App은 커스텀 plist라 실제로 빠져 있었다, `App/CLAUDE.md`). `Tuist/Package.swift` `productTypes`에
      `.framework` 강제 필수(안 하면 `MustInitAppKey` 크래시, `OnboardingFeature/CLAUDE.md`).
    - 받는 쪽 라우팅은 App 몫(`App/CLAUDE.md`의 딥링크 항목). VM에 `shareTapped` 액션은 없다 — 순수 표현이라
      View가 직접 처리한다(`onNovelTapped`와 같은 위상).
    - **폐기 이력(시스템 공유 시트, 커밋 `0cd2f144`·`bffdbe1e`·`5d1e0b78`에 구현이 남아 있다)** — 나중에 Universal
      Link로 시트를 되살릴 때 같은 함정을 다시 밟지 않도록 요점만: `ShareLink(item: URL, message:)`는 "복사"가
      URL과 메시지를 별개 pasteboard 항목으로 넣어 plain-text 입력창(카카오톡)에 URL이 빠지고,
      `ShareLink(item: String)`은 문자열을 파일로 취급해 "복사"가 아예 없으며, `.sheet { UIActivityViewController }`는
      시트 안의 X/완료가 SwiftUI 표시 상태와 어긋나 **두 번째부터 안 뜬다** → 투명 호스트 VC가 창 최상위 VC에서
      직접 present하고 `completionWithItemsHandler`로 상태를 내리는 프레젠터가 답이었다. 시트 모양(detent 등)은
      iOS 26 공유 시트가 우리 설정을 무시하며, 컨테이너 child로 강제하면 흰 백드롭이 앱을 덮는다(전부 iOS 26.5
      실측, 2026-08-29). 미리보기 표지 로드용으로 만든 `WSSComponent.WSSImageLoader`는 `WSSAsyncImage`가 쓰므로 남아 있다.
  - **"컬렉션 수정"은 `CreateCollectionView`를 수정 모드로 재사용하는 별도 Factory 진입점
    (`makeEditCollectionView`)이다** — 더보기 메뉴 탭 → `onEditTapped()`로 App에 알리면 App이 push한다
    (#201부터, 로컬 push 아님). 이 화면도 `CollectionListView`와 같은 `hasAppearedOnce` 플래그로 복귀를
    감지한다(App 경로의 자식이 수정 화면 하나뿐이라 최초 이후 재발화는 곧 "수정에서 돌아옴") —
    성공/취소 구분 없이 무조건 `.reloadAfterEdit`로 다시 불러온다(이미 `state.detail`이 있어 전면
    로딩으로 안 덮인다, 정렬 변경과 동일 UX).
  - 삭제는 확인 알럿(`WSSAlertType.deleteCollection`, "삭제한 컬렉션은 되돌릴 수 없어요") 필수 —
    Figma엔 알럿이 없지만 파괴적 액션은 항상 확인을 거치는 프로젝트 관례를 따른다(`deleteMyFeed`/
    `deleteMyComment`와 동일 패턴). 성공 시 `shouldDismiss`로 화면을 닫는다(삭제된 컬렉션은 더 볼 수
    없어 화면에 남아있을 이유가 없음 — `UserPageFeature`의 차단 성공과 동일 판단).
  - "공유" 아이콘(`icShare`, Figma `humbleicons:share`)은 이 작업에서 `DesignSystem`에 신규 추가한
    에셋이다(기존엔 없었음, 사용자 승인).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **App이 push하는 화면의 "진입 파라미터"는 반드시 `NavigationPath`의 `Destination` payload로
  실어 보내야 한다 — 별도 `@State` 스크래치 변수에 먼저 쓰고 그 변수를 읽어 destination view를
  만드는 방식은 레이스가 있다(#201, 사용자 리포트로 실측 재발견 — "작품 추가→서재에서 추가로 넘어가면
  검색에서 고른 작품이 사라진다").** 원인: `MypageRootView`(App)가
  `libraryInitialSelection = currentSelection; path.append(.myLibrarySelectForCollection)`처럼 같은
  액션 안에서 `@State` 갱신과 push를 연달아 실행해도, `.navigationDestination(for:)`가 새
  destination view를 만드는 시점에 그 `@State` 갱신이 **아직 반영되지 않은 이전 값**(빈 배열)을 읽어
  `CollectionMyLibrarySelectViewModel.init(initialSelection:)`이 빈 배열로 초기화됐다(디버그 로그로
  확인 — `handleLibrarySelectTapped`가 찍은 `currentSelection.count`는 2였는데, 그 직후
  `ViewModel.init`이 찍은 `initialSelection.count`는 0). `CollectionListView`의 "컬렉션 목록 (빈
  상태)" `isEmpty: Bool`처럼 **값 타입이 이미 Hashable인 payload는 이 레이스가 없다** — 문제는 오직
  "Hashable이 아니라서 어쩔 수 없이 스크래치 `@State` + 사이드채널로 우회하던" 경우다.
  **고친 방법**: `CollectionNovel`을 `Hashable`로 만들고(필드가 전부 Hashable이라 캐스케이드 없이
  자동 합성만으로 충분, `CollectionDomain/CLAUDE.md` 참고), `Destination.searchNovelForCollection`/
  `.myLibrarySelectForCollection`이 `[CollectionNovel]`을 직접 들고 다니게 바꿨다 — 스크래치 `@State`
  (`collectionSearchNovelInitialSelection`/`collectionLibraryInitialSelection`, Demo의
  `searchNovelInitialSelection`/`libraryInitialSelection`)는 전부 제거됐다. **새로 "진입 파라미터가
  있는 push 화면"을 추가할 때 그 파라미터 타입이 아직 Hashable이 아니면, 스크래치 `@State`로 우회하지
  말고 먼저 그 타입을 Hashable로 만들 수 있는지부터 검토할 것** — 캐스케이드가 없으면(다른 비Hashable
  타입을 필드로 안 담고 있으면) 거의 항상 가능하고, 이 레이스를 구조적으로 없앤다.
  ⚠️ **반대 방향(화면이 App에 결과를 돌려주는 "확정 값")은 이 레이스 대상이 아니다** — `pendingNovelSelection`
  처럼 이미 mount된 화면이 `.onChange`로 관찰하는 Binding 채널은 안전하다(위 "진입점" 절 참고). 레이스는
  오직 "아직 mount 안 된 destination이 방금 쓴 `@State`를 못 읽는" 진입(entry) 방향에서만 난다.

- **`CollectionDetailViewModel`은 `isClosing` 가드를 갖는다(#201, 사용자 확정 — 리뷰가 지적했을 땐
  형제 VM들과의 일관성을 이유로 한 라운드 보류했다가, 이후 이 화면에 한해 반영하기로 뒤집었다)** —
  뒤로가기 버튼이 `viewModel.handle(.backTapped)`를 부른 뒤 `dismiss()`하면 `close()`가 `isClosing`을
  세우고 `loadTask`/`likeTask`를 취소한다(`NovelDetailViewModel.close()`와 같은 "명시적 액션" 변형).
  삭제 성공(`deleteCollection()`)도 같은 `close()`를 타는 진짜 exit로 취급한다 — `confirmDelete`가
  스폰하는 삭제 Task 자신은 취소하지 않는다(확인 알럿을 거친 명시적 요청이라 화면이 닫히는 도중이어도
  서버 반영까지 보낸다, `NovelReviewViewModel.close()`가 저장 Task를 안 취소하는 것과 동일 판단).
  ⚠️ **`View.onDisappear`로 세우는 변형(`NovelNotificationSettingSheetViewModel.disappear()`)은 여기
  못 쓴다 — 처음엔 그 변형을 그대로 옮겨왔다가 리뷰에서 실제 회귀로 발견됐다.** 발견 당시엔 "컬렉션
  수정"이 이 화면의 **로컬 push**였지만(`isEditPresented`), #201에서 App으로 옮긴 지금도 원인은
  그대로 유효하다 — `MypageRootView`가 같은 `NavigationPath`에 "컬렉션 수정"을 push하면, 그 push가
  App 소유든 예전처럼 Feature 로컬 소유든 상관없이 **push되는 순간 이전 화면(`CollectionDetailView`)의
  `.onDisappear`가 SwiftUI 표준 동작으로 함께 발화한다.** 그 시점에 `isClosing`이 `true`로 굳고
  되돌리는 코드가 없으면, 수정 화면에서 복귀한 뒤 재조회(`.reloadAfterEdit`)는 물론 정렬 변경·좋아요·
  삭제까지 전부 조용히 무반응이 된다(alert도 안 닫힘, 콘솔 로그도 안 찍힘 — 겉보기엔 화면이 "고장").
  `onDisappear` 기반 변형은 **같은 `NavigationPath`에서 자기 위로 뭔가 push될 일이 없는 리프 화면
  (시트 등)에서만** 안전하다 — 이 화면처럼 같은 스택 위에 다른 화면이 push되면(App이 하든 Feature가
  하든) 명시적 액션(`NovelDetailViewModel` 쪽 변형)을 쓸 것. **`CollectionListViewModel`/
  `CreateCollectionViewModel`/`CollectionSearchNovelViewModel`/`CollectionMyLibrarySelectViewModel`은
  아직 이 패턴이 없다** — 이번엔 리뷰가 지적한 화면 하나만 고쳤을 뿐, 모듈 전체 일괄 적용은 아니다.
- **`CollectionListViewModel`은 표준 VM 섹션 순서(`Feature/CLAUDE.md`) 끝에 `// MARK: - Tab Bookkeeping
  Access`를 추가로 둔다** — 탭 2개(`.mine`/`.liked`)를 동시에 부기해야 하는 첫 사례라, 그 접근자
  헬퍼(`bookkeeping(for:)`/`content(for:)`/`update...`)가 기존 6개 섹션 어디에도 자연스럽게 안
  맞는다. 새 화면에서 같은 "여러 하위상태를 키로 나눠 관리" 패턴이 또 필요하면 이 예외를 정본으로
  삼아도 된다 — 단, 섹션을 늘리는 걸 기본값으로 삼지 말고 정말 기존 섹션에 안 맞을 때만.
- ⚠️ **상세(`CollectionDetailView`) 복귀 시 `.reloadAfterReturn`(구 `reloadAfterDetail` — #201에서
  `CreateCollectionView` 복귀와 액션을 합치며 이름도 일반화됐다)은 그 순간 선택된 탭만 재로드한다 —
  반대편 탭은 `hasLoaded`를 꺼서(`invalidate`) 다음에 그 탭으로 전환할 때 자동으로 새로 불러오게
  한다.** 좋아요 토글은 "좋아요한 컬렉션" 목록 자체를 바꾸는데, "내 컬렉션"에서 상세로 들어가
  좋아요를 누르고 돌아오면 그 순간 화면엔 "내 컬렉션"이 떠 있으니 그것만 재로드되고 "좋아요한
  컬렉션"은 손대지 않으면 lazy 1회 로드 정책(`hasLoaded`) 때문에 나중에 그 탭으로 가도 옛 목록이
  그대로 보인다(실제 버그로 발견). 지금 안 보이는 탭을 그 자리에서 바로 재요청하지 않고 **다음 방문
  시점으로 미루는 이유**는 반대편 탭이 화면 밖일 수도 있는 상태에서 즉시 재요청하면 낭비이기 때문 —
  새로 "카드가 양쪽 탭에 다 영향줄 수 있는" 액션을 추가할 땐 이 `invalidate(otherTab(of:))` 패턴을
  따를 것.
  ⚠️ **`invalidate`는 `hasLoaded`만 끄는 게 아니라 `generation`도 함께 올려야 한다** — 무효화하는
  시점에 반대편 탭이 이미 로드 중이었다면(화면 전환 직전에 시작된 요청 등), 그 진행 중 `Task`가
  뒤늦게 성공하며 `loadPage`의 성공 분기가 `hasLoaded`를 다시 `true`로 되돌려버려 무효화 자체가
  무의미해질 수 있다(PR 리뷰에서 발견, 발생 조건은 좁지만 재현 가능). `generation`을 함께 올리면
  `loadPage`가 이미 갖고 있는 generation 가드(`bookkeeping(for: tab).generation == generation`)가
  그 뒤늦은 완료를 걸러낸다 — 별도 가드를 새로 안 만들어도 된다.
- ⚠️ **`CollectionListView`의 두 탭(내 컬렉션/좋아요한 컬렉션)은 각자 자기 스크롤 뷰를 갖고, 안 보이는
  쪽도 지우지 않고 opacity로만 숨긴다**(`LibraryFeature`의 그리드↔리스트 토글과 동일 함정·동일 해법,
  실측으로 재확인) — 하나의 스크롤 뷰 안에서 `if`/`switch`로 탭 콘텐츠만 갈아끼우면 SwiftUI가 그
  스크롤 뷰의 정체성을 유지해 **contentOffset이 두 탭에 공유된다**(좋아요한 컬렉션에서 스크롤해 두고
  내 컬렉션으로 돌아오면 이미 스크롤된 채로 보임). 배포 타깃 iOS 17이라 `ScrollPosition`(iOS 18+)을 못
  써서 "동시에 마운트해두고 숨기기"가 유일한 해법이다. 이 구조 때문에 `.loadMore`/`.retry` 액션은
  **`state.selectedTab` 암묵 참조 대신 대상 탭을 명시로 받는다** — 안 보이는 탭의 리스트도 화면에
  계속 존재해 그 셀의 `onAppear`가 fire될 수 있는데, 액션이 "현재 선택된 탭"을 가정하면 안 보이는
  탭의 이벤트가 엉뚱하게 보이는 탭에 적용된다.
- ⚠️ **`CollectionSegmentedTab`의 탭 라벨은 `.onTapGesture`가 아니라 `Button`으로 감싼다** —
  `.onTapGesture`는 접근성 트리에 안 잡혀 VoiceOver·UI 자동화(`snapshot_ui`/`tap`) 모두 탭할 수 없다
  (`WSSComponent/CLAUDE.md` 공통 함정, `WSSLibraryGridCell` 항목과 동일 재발 — 실측: `snapshot_ui`가
  탭 텍스트를 `tap` 대상이 아닌 `text`로만 보고했다가 `Button`으로 바꾸자 `tap` 대상으로 잡힘). 새
  탭/세그먼트 컴포넌트를 만들 때 습관적으로 `.contentShape` + `.onTapGesture`를 쓰지 말고 `Button`을
  기본으로 삼을 것.
- **`CollectionSegmentedTab`의 인디케이터 슬라이드는 `matchedGeometryEffect`(선택된 탭에만 조건부로
  존재)로 구현한다** — `SearchFeature.DetailSearchFilterView`(`FeedFeature.SosoFeedView`와 동일 패턴)를
  그대로 따랐다(사용자 지정 레퍼런스). 처음엔 이 방식이 `LibraryFeature`가 남긴 "선택된 쪽에만 `if`로
  그리고 `matchedGeometryEffect`로 이으면 이동이 아니라 크로스페이드로 보인다"는 함정과 충돌한다고
  보고 `.offset(x:)` 수동 계산으로 짰지만, 실측(시뮬레이터)해보니 오히려 부자연스러웠다 — **그 함정은
  `LazyVGrid`로 재활용되는 셀 안의 아이콘**(원본 사례) 얘기였고, 이 탭바처럼 정체성이 고정된 화면
  최상단 뷰에서는 `matchedGeometryEffect`가 정상적으로 슬라이드한다. 인디케이터는 하단 구분선
  (`Rectangle().fill(Color.wssGray70)`)과 같은 `ZStack(alignment: .bottom)`에 겹쳐 그 선 위를 타고
  움직이는 것처럼 배치한다(구분선을 먼저 깔고 탭 버튼을 그 위에 얹는 순서).
- ⚠️ **2단계 pop("서재에서 추가" 확정 → 생성/수정 화면까지)은 #201부터 App(`MypageRootView` 등)이
  소유한다 — Feature 안에는 더 이상 이 로직이 없다.** App은 `handleLibrarySelectConfirm`(App 쪽 이름,
  모듈마다 호출자가 붙임)에서 `pendingNovelSelection`에 결과를 채우고 같은 프레임에 `path.removeLast(2)`
  를 호출해 "서재에서 추가"+"작품 추가" 두 destination을 한 번에 pop한다("작품 추가" 확정(1단계 pop)은
  `path.removeLast(1)`). **아래는 이 2단계 pop을 처음 Feature 내부(로컬 push)로 구현하던 시절 실측으로
  얻은 교훈이다 — App으로 옮긴 지금도 결론은 그대로 적용된다**: 여러 단을 pop할 땐 중간 화면이 각자
  `dismiss()`(App 기준으로는 `path.removeLast(1)`)를 부르는 계단식 방식도, 화면 간 구조 자체를 바꾸는
  방식도 아니고, **최상위(App)가 확정 콜백 안에서 필요한 만큼을 한 번에 pop**하는 것만 검증된 정본이다.
  ⚠️ **Feature 시절엔 "자식이 스스로 pop → 부모가 `onChange`로 그 완료를 감지해 뒤이어 pop"하는 계단식
  2회 `dismiss()` 방식(`isPendingDismissAfterMyLibrarySelect` 플래그)을 썼었다** — 그건 "자식의
  `dismiss()`와 부모의 `dismiss()`를 같은 프레임에서 함께 부르면 부모가 pop되지 않는다"는 실측 버그를
  피하려는 것이었는데, 정작 그 계단식 2회 pop 자체가 **두 전환 애니메이션이 거의 같은 프레임에 겹쳐
  보여 "추가" 탭 후 화면이 이중으로 dismiss되는 것처럼 보이는** 새 문제를 냈다(사용자 리포트). "한 번에
  필요한 만큼 pop"(Feature 시절엔 최상위 boolean 하나, 지금은 App의 `path.removeLast(N)`)은 애초에
  pop이 한 번만 발생하므로 이 겹침 문제 자체가 생기지 않는다 — 계단식 방식으로 되돌리지 말 것.
  ⚠️ **폐기한 대안 둘 다 다른 이유로 깨졌다(2026-08-24 실측, 아직 Feature가 로컬 push를 소유하던
  시절)** — 지금 방식과 달리 **둘 다 화면 간
  구조 자체를 바꾸려던 시도**였다는 점에 유의(지금 방식은 구조는 그대로 두고 "누가 dismiss를 부르는지"만
  최상위로 모은 것):
  1. **형제 Bool 교체** — `CreateCollectionView`가 검색 화면과 서재 화면을 형제 레벨로 각각 직접 push해
     "서재에서 추가" 진입 시 검색 화면을 아예 pop해버리는 방식. **확정** 경로는 문제없이 동작했지만,
     **확정 대신 뒤로가기로 서재 화면을 나가면 되돌아갈 검색 화면 자체가 스택에 없어 그 세션에서 고른
     작품이 조용히 사라졌다**(리뷰에서 `wss-pr-reviewer`/`wss-feature-reviewer` 둘 다 독립적으로 지적).
  2. **`CreateCollectionView`가 자기 `NavigationStack(path:)`를 새로 열고 `.navigationDestination(for:)` +
     `path: [AddNovelRoute]` 배열로 두 화면을 push** — 뒤로가기 상태 보존은 되나, **이 화면 안에서
     호출한 `dismiss()`가 그 내부 스택이 아니라 바깥(진짜) 스택을 pop해버려**, 검색 화면에서 뒤로가기
     한 번 눌렀더니 `CreateCollectionView`를 지나 데모 루트까지 곧장 튕겨 나갔다(중첩
     `NavigationStack` 안에서 `@Environment(\.dismiss)`가 어느 스택을 pop할지 모호해지는 것으로 추정).
     `CreateCollectionView`가 이미 바깥 스택에 push된 상태에서 또 다른 `NavigationStack`을 그 안에
     여는 패턴은 이 프로젝트에서 쓰지 말 것.
  다단계 push에서 "확정만 skip, 취소는 정상 pop"이 필요할 땐 **뒤로가기는 각 화면이 그대로 개별
  `dismiss()`(App 기준 `path.removeLast(1)`)를 유지하고, 확정만 콜백을 타고 최상위까지 올라가 그쪽에서
  필요한 만큼 한 번에 pop하는 지금 패턴**이 유일하게 검증된 정본이다 — 형제 Bool 교체나 중첩
  `NavigationStack`으로 "더 깔끔하게" 다시 풀어보려 하지 말 것(둘 다 이미 실측으로 폐기됨). App으로
  옮긴 뒤에도 같은 함정이 유효하다 — App의 `Destination` enum 안에서 검색/서재 화면을 별개 형제
  케이스로 다루면서 "서재에서 추가"가 검색 화면을 대체하듯 push하는 식으로 짜면 위 1번과 같은 유실이
  재현될 수 있으니, 반드시 **push는 각 단계마다, pop만 확정 시점에 필요한 개수만큼 한 번에**의 원칙을
  지킬 것(`MypageRootView.handleCollectionLibrarySelectConfirm` 참고).
- ⚠️ **iOS 18.1 시뮬레이터 런타임에서 `CollectionSearchNovelView`로 push하면 진입 즉시 CPU 100%
  무한 리렌더(AttributeGraph 루프)에 빠진다 — 앱·이 화면의 버그가 아니라 그 OS 런타임 한정 SwiftUI
  회귀로 확인됨.** 같은 빌드 산출물을 iOS 26 시뮬레이터에 설치해 동일 자동화 경로로 재현했을 땐 CPU
  0%로 정상 동작했다(화면 전환·"서재에서 추가"·대표 배지까지 전부 정상). 이 화면을 시뮬레이터에서
  검증할 땐 **iOS 18.1을 피하고 최신 iOS 런타임 시뮬레이터를 쓸 것** — CPU가 진입 직후 100%에 붙박이면
  코드가 아니라 시뮬레이터 런타임부터 의심할 것.
- **(#199 시절 함정, #201에서 구조적으로 해소됨)** 화면이 화면을 로컬로 push하던 시절엔 `logger`가
  자동으로 안 흘러 중간 화면의 `init`에 파라미터를 빠뜨리면 조용히 `nil`로 굳는 함정이 있었다. #201부터
  "작품 추가"/"서재에서 추가"가 각각 독립된 Factory 진입점(`makeSearchNovelView`/`makeMyLibrarySelectView`)
  이 되면서 **App이 화면마다 직접 `logger:`를 넘긴다** — 더 이상 앞 화면을 거쳐 체인으로 내려보낼 필요가
  없어 이 함정 자체가 사라졌다. 같은 함정이 재발하려면 이 모듈이 다시 화면 안에서 화면을 로컬 push하는
  구조로 돌아가야 하는데, 그건 이 문서의 다른 주의사항들(2단계 pop 등)이 이미 하지 않기로 확정한 방향이다.
- ⚠️ **`WSSLibraryGridCell`은 탭 동작을 갖지 않는 순수 표시 뷰라, 이 화면처럼 `.onTapGesture`로 감싸
  탭 영역을 만들면 접근성 트리에 안 잡혀 VoiceOver는 물론 UI 자동화(`snapshot_ui`/`tap`)로도 탭할 수
  없다**(`WSSComponent/CLAUDE.md` 공통 주의) — `.accessibilityLabel(novel.title)` + `.accessibilityAddTraits(.isButton)`을
  `CollectionMyLibrarySelectView`의 셀 래퍼에 걸어야 자동화 탭 대상으로 잡힌다(2단계 pop 실측 검증에
  실제로 필요했다). 이 컴포넌트를 새 화면에서 탭 가능하게 감쌀 때 이 트레잇을 빠뜨리지 말 것 — 특히
  다중선택 화면처럼 탭이 핵심 동작인 셀일수록 VoiceOver 접근성 공백이 치명적이다.
- ⚠️ **`CollectionSearchNovelViewModel`(구 `AddNovelViewModel`)의 검색 결과 영역은 `searchedNovels`가
  아니라 `hasSearched` 플래그로 가른다** — `WSSSearchBar`의 `onSearch`는 제출(엔터/검색 버튼)에만
  발화하고, 타이핑 자체는 `updateSearchText`로 매 글자마다 바로 반영된다. `searchedNovels`(또는
  `searchText`) 유무만으로 "결과 없음" 뷰를 켜면, 검색을 실행하기도 전에(타이핑 도중) 또는 이전 검색
  결과를 두고 다음 검색어를 입력하는 도중에 잘못된 뷰(결과없음/직전 결과)가 보인다(실제 발생 — 사용자
  리포트: 타이핑 중엔 흰 배경이어야 함). `updateSearchText`가 매번 `hasSearched = false`로 끄고,
  `searchNovels(_:)`가 응답을 **실제로 받은 뒤에만** `hasSearched = true`로 켠다 — `resultArea`는
  `!hasSearched`면 무조건 빈 화면, 그 다음에야 `searchedNovels` 유무로 리스트/결과없음을 가른다.
  **`FeedFeature`의 `CreateFeedConnectNovelSheet`도 같은 검색 흐름(같은 `WSSNovelSelectRow` 기반)이라
  동일 패턴으로 맞춰졌다** — `hasSearched`가 View의 로컬 `@State`가 아니라
  `CreateFeedViewModel.state.hasSearchedNovel`로 VM 소유로 옮겨졌고, `updateConnectedNovelSearchText`가
  매번 껐다가 검색 응답을 받아야만 켜진다(자세한 내용은 `FeedFeature/CLAUDE.md` 참고). **새 검색+
  무한스크롤 화면을 또 만들 땐 이 두 구현을 정본으로 삼을 것** — `searchTask`(또는 동등한 진행 중 Task
  프로퍼티)를 완료 시 `nil`로 되돌리는 걸 빠뜨리면 `loadMore()`류 가드가 첫 검색 이후 영원히 막히는
  함정도 공유하니 함께 챙길 것(`CollectionSearchNovelViewModel`도 한 번 이 버그를 실제로 냈다가 고쳤다,
  `CollectionMyLibrarySelectViewModel`은 처음부터 커서+generation 패턴을 써서 이 특정 함정은 없다).
- **`CreateCollectionViewModel`에 `#if DEBUG` 전용 `init(previewDraft:previewNovelDisplayInfo:createCollectionUseCase:)`가 있다** —
  `CollectionSearchNovelView`가 생기기 전, 작품 리스트 그리드(대표 배지 포함)를 볼 유일한 경로가 Xcode
  Preview뿐이던 시절 만든 시각 확인용 우회로다. 지금은 Demo 앱에서도 "작품 추가" → 검색·선택/"서재에서
  추가" → "완료"/"추가"로 실제 채워볼 수 있지만, 이 init은 여전히 **Preview 전용**으로 남겨둔다(다른 셀
  배치를 즉시 볼 수 있어 유용) — **Factory·프로덕션 코드는 쓰지 않는다**. `CreateCollectionView.swift`의
  `#Preview("작품 포함")`에서만 사용.
- ⚠️ **`addNovelTile`과 `novelGridCell`은 같은 그리드 행을 채우므로 커버 박스 사이즈 산정 방식(`novelCoverAspectRatio`)과
  "제목 줄" 유무를 반드시 맞춰야 한다** — 처음엔 `addNovelTile`만 고정 `height: 156`을 썼는데, 옆
  `novelGridCell`은 커버(가변 높이) + 제목 텍스트(최대 2줄)로 총 높이가 더 길어 행이 어긋나 보였다
  (#199 리뷰 피드백). 지금은 둘 다 같은 `aspectRatio`로 커버를 그리고, 제목 자리는 `Metric.novelTitleHeight`
  (고정 38, `.body4` 2줄 기준)로 예약한다. 셀 종류를 늘릴 땐 이 짝을 깨지 말 것.
  - ⚠️ **제목 자체도 셀마다 1줄/2줄로 갈리면 `novelGridCell`끼리도 행이 어긋난다** — 처음엔 제목
    `Text`가 `lineLimit(2)`만 걸린 자연 높이였는데, 짧은 제목(1줄)과 긴 제목(2줄)이 같은 그리드에
    섞이면 셀마다 총 높이가 달라졌다. `WSSNovelGridCell`의 `Metric.infoHeight`와 같은 패턴으로,
    제목 `Text`에 `.frame(height: Metric.novelTitleHeight, alignment: .top)`을 직접 걸어 줄 수와
    무관하게 위에서부터 채우고 남는 공간은 비워둔다. `addNovelTile`은 제목이 아예 없어 폰트를 맞춘
    투명 텍스트 대신 같은 높이의 빈 `Spacer()`면 충분하다.
  - ⚠️ **`.aspectRatio(_, contentMode:)`를 `VStack`(텍스트·아이콘만 있는, `Spacer` 없는) 같은 "내용물이
    작은 뷰"에 직접 걸면 그 뷰가 그리드 칸을 안 채우고 내용물의 자연 크기(이 경우 ~41pt)로 쪼그라든다**
    (실측 — `addNovelTile`을 처음 이 방식으로 고쳤다가 타일이 왼쪽 위에 작게 뜨는 걸 발견, #199). `.frame(maxWidth: .infinity)`를
    앞에 끼워도 높이 방향은 안 채워진다. **`WSSNovelCoverImage`가 쓰는 것과 같은 해법**: `Color.clear`가
    `.aspectRatio`로 비율·크기를 잡고, 실제 콘텐츠는 `.overlay { ... }`로 그 위에 얹는다 — `Color.clear`는
    어떤 제안 크기든 그대로 받아들이므로 aspectRatio가 계산한 박스 전체가 항상 채워진다.
- ⚠️ **`CollectionDetailView.novelCell`은 표지 크기를 제목/작가와 절대 같은 `.frame(height:)`로 묶지
  않는다** — 한때 표지+제목+작가 전체를 `.frame(height: 216)` 하나로 묶었는데, 그러면 2줄로 꺾이는
  제목이 그 고정 예산을 표지와 나눠 쓰게 돼 **표지 실제 렌더 폭이 열 너비보다 좁아지는 버그**가
  있었다(사용자가 파란 배경 디버그로 실측 발견, 짧은 제목 Mock 데이터로는 재현이 안 됐다 —
  `DemoLoadCollectionDetailUseCase`가 이제 3의 배수 인덱스에 일부러 긴 제목을 섞어 이 케이스를
  Mock에서도 잡는다). 표지는 `aspectRatio`만으로 독립적으로 크기를 정해 제목 줄 수의 영향을 아예
  안 받게 한다 — **셀 전체를 하나의 `.frame(height:)`로 묶는 패턴을 이 모듈의 다른 그리드 셀에도
  다시 쓰지 말 것.**
  - ⚠️ **제목 자체도 `addNovelTile`/`novelGridCell`(`CreateCollectionView`)이 쓰는 고정 높이 박스
    (`Metric.novelTitleHeight`, 2줄 기준 예약)를 따라 하지 않는다** — 처음엔 그 패턴을 그대로
    옮겨와 `.frame(height: 38, alignment: .top)`을 줬으나, 그러면 제목이 1줄일 때 박스 안 남는
    공간만큼 작가 텍스트 앞 여백이 쓸데없이 넓어졌다(사용자 확정, 2026-08-25 — 제목 줄 수와 무관하게
    제목-작가 간격은 항상 `Spacer(2)`만큼만이어야 함). `.fixedSize(horizontal: false, vertical: true)`
    로 제목이 실제 필요한 높이(1줄/2줄)만 쓰게 하고 그 바로 뒤에 고정 2pt 간격만 둔다 — 그리드 행
    안에서 제목 줄 수가 다른 셀끼리는 카드 전체 높이가 달라질 수 있지만(짧은 셀 아래 여백), 표지
    폭·정렬은 위 문제와 이미 분리돼 있어 영향 없다. `CreateCollectionView.novelGridCell`은 여전히
    고정 높이 박스를 쓴다 — **두 화면의 제목 높이 정책이 이제 의도적으로 다르다**(이 화면은 열람
    그리드라 카드 아래 여백 차이가 자연스럽고, 그쪽은 편집 그리드라 행 정렬이 더 중요한 것으로 판단),
    맞추려 하지 말 것.
  - ⚠️ **위 "제목 줄 수가 다른 셀끼리는 카드 높이가 달라진다"는 이후(2026-08-25) 실제로 문제가 돼
    카드 높이 216 통일 요구로 이어졌다** — 표지는 여전히 건드리지 않고, "제목+간격(2)+작가"를 감싸는
    서브스택(`novelCellInfo(_:)`)에만 `.frame(height: novelInfoHeight, alignment: .top)`을 걸어
    해결했다(`WSSNovelGridCell.Metric.infoHeight`와 동일 원리 — 표지와 정보 스택을 같은 프레임으로
    묶지 않는 한 위 버그는 재현되지 않는다). 서브스택 끝의 `Spacer(minLength: 0)` + `alignment: .top`
    덕에 제목이 1줄이라 남는 공간은 항상 작가 텍스트 아래(카드 하단)로 흐른다 — 제목-작가 간격
    자체는 여전히 고정 `Spacer(2)`라 줄 수와 무관하게 2pt로 유지된다. `novelInfoHeight` 값은 시뮬레이터
    실측(1줄/2줄 제목이 섞인 그리드에서 바닥선·표지 폭 확인)으로 정했다.
- ⚠️ **`CollectionDetailView`의 스크롤 반응형 네비 타이틀은 `opacity` 모디파이어가 아니라 `if` 구조적
  조건으로 넣고 뺀다** — 시스템 `.toolbar { ToolbarItem(.principal) { Text().opacity(조건 ? 1:0) } }`
  조합은 opacity 값만 바뀌어선 UIKit 브리지(titleView)에 갱신되지 않고 계속 숨어있는다(#201 실측,
  `Feature/CLAUDE.md` 공통 주의사항에 일반화해 남김 — `UserPageFeature`도 동일 재발).
- **히어로 표지는 `.frame(height:, alignment: .top)`으로 상단 기준 크롭한다**(기본값 `.center`
  대신) — `scaledToFill()`로 프레임보다 커진 이미지가 위쪽부터 정렬된 뒤 잘리게 하려는 의도. 가로는
  이미 화면 폭을 꽉 채운 상태라 세로 정렬만 바뀐다.
- **히어로 표지는 당겨서 새로고침(오버스크롤) 중에도 흰 배경이 비치지 않고 화면 최상단까지 확대되며
  늘어나는 "스트레치 줌 헤더"로 구현돼 있다** — `heroSection`의 `GeometryReader`가
  `scrollCoordinateSpace`(스크롤 반응형 네비 타이틀과 **같은** named coordinate space)에서 읽은
  `minY`가 양수면(콘텐츠가 아래로 밀린 상태 = 오버스크롤) 그 값(`stretch`)을 두 군데에 쓴다:
  `scaleEffect(1 + stretch / heroBackgroundHeight, anchor: .top)`로 이미지를 확대하고,
  `.offset(y: -stretch)`로 같은 양만큼 위로 끌어올린다. **hold 구간(임계값) 없이 당기는 즉시 그
  값에 비례해 확대된다** — 처음엔 일정 거리(30pt)까진 커버리지만 하고 그 이상 당겨야 확대되는 2단계
  구조도 시도했으나, 실제로 써보니 "일단 스크롤하면 바로 확대되는 게 낫다"고 확정됐다(2026-08-25).
  바깥 `GeometryReader` 자체는 여전히 `.frame(height: heroBackgroundHeight)`로 고정돼 있어 정보
  영역(닉네임·제목 등)의 위치는 전혀 안 밀린다.
  - ⚠️ **프레임 높이만 키우는 방식(`.frame(height: heroBackgroundHeight + stretch)`)만으로는 확대되는
    느낌이 안 난다** — 표지가 세로로 긴 작품 썸네일이라 `scaledToFill`이 정지 상태에서 이미 가로 폭
    기준으로 세로 방향을 넉넉히 넘치게 스케일해둔 상태다. 그 상태에서 프레임 높이만 늘리면 스케일
    계수가 그대로라(가로 폭이 여전히 지배적이라) 확대 없이 원래 잘려나가 있던 여백만 그대로
    드러난다(실측 — "이상하다"는 사용자 피드백으로 발견). 그래서 정지 상태 크롭을 먼저
    `.frame(height: heroBackgroundHeight, alignment: .top).clipped()`로 고정한 뒤, 그 결과물 자체를
    `scaleEffect`로 키우는 지금 방식으로 바꿨다 — 표지가 세로로 긴 이미지라면 프레임 확장 방식은
    다시 쓰지 말 것.
  - ⚠️ **그라디언트(`LinearGradient`)는 반드시 이미지와 같은 변환 체인 안(`heroImageWithGradient`)에
    넣는다** — 형제 레이어로 따로 두면 이미지만 늘어나고 그라디언트는 `heroBackgroundHeight`에
    고정된 채로 남아, 오버스크롤 중 이미지 위쪽이 그라디언트 없이 그대로 드러난다(실측 — "그라디언트가
    잘려 보인다"는 사용자 피드백으로 발견). 이미지+그라디언트를 한 뷰로 묶은 뒤 프레임·스케일·offset을
    그 묶음 전체에 걸어야 항상 같이 움직인다.
  - `minY` 신호를 스크롤 감지(`isScrolledFromTop`)와 스트레치 계산 둘 다에 공유해서 쓰는 것도
    재사용 포인트(별도 `GeometryReader`를 새로 만들 필요 없음).
- ⚠️ **정렬 변경(`WSSSortButton`) 재조회는 이미 `state.detail`이 있는 상태라 전면 `LoadingView()`로
  덮지 않는다** — `isLoading`만 보고 덮으면 히어로·그리드가 전부 사라졌다 다시 그려져 화면이 통째로
  깜빡인다(사용자 리포트). `viewModel.state.isLoading, viewModel.state.detail == nil`처럼 **"진짜
  아무것도 없는 첫 로드"일 때만** 전면 로딩을 보여줄 것 — `FeedFeature.SosoFeedView`의
  `isLoading && currentFeeds.isEmpty` 판단과 동일 패턴이다. 재조회 실패는 여전히 `hasLoadError`로
  전면 실패 뷰가 뜬다(`Feature/CLAUDE.md`의 "로드 실패 표현 계약"대로 갱신 실패도 첫 로드와 동일하게
  다룸 — 이건 의도한 동작이라 건드리지 않았다).
- **`CollectionListView`의 `isOwnCollections: Bool`(기본 `true`, #201 후속·2026-08-28)은 타유저
  프로필(`UserPageFeature`)의 "컬렉션" 헤더 탭이 이 화면을 재사용할 수 있게 연 스위치다** — "좋아요한
  컬렉션" 탭이 세션 토큰=로그인 사용자 자신 기준이라, 애초에 이 화면 전체가 "로그인 사용자 자신
  기준으로만 동작"했다(위 진입점 절 참고). `false`면 `CollectionSegmentedTab`과 "컬렉션 만들기"
  버튼(리스트 상단·빈 상태 둘 다)을 감춰 "내 컬렉션" 콘텐츠만(`userID`는 여전히 대상 유저) 보여준다.
  ⚠️ **`CollectionListViewModel`은 손대지 않았다** — 세그먼트 탭이 안 보이면 `.selectTab(.liked)`를
  호출할 UI 자체가 없어 `state.selectedTab`이 기본값 `.mine`에서 벗어날 방법이 없다. 새로 이 화면에
  "모드"를 하나 더 추가할 일이 생기면, ViewModel까지 갈라야 하는지 먼저 확인할 것 — 이번처럼 순수
  화면 표시 분기(View 전용)로 끝나는 경우가 있다.
  ⚠️ **빈 상태(`emptySection(for: .mine)`)의 `isOwnCollections == false` 분기는 사실상 도달하지
  않는다** — 정상 경로는 `UserPageFeature`가 헤더 탭 시점에 `hasCollections`를 먼저 보고, 컬렉션이
  0개면 이 화면 자체를 push하지 않고 토스트로 대신 응답한다(`UserPageFeature/CLAUDE.md` 참고).
  그래도 방어적으로 남겨뒀다 — 삭제하지 말 것(경합으로 0개가 된 채 이미 push된 경우의 안전망).
  `WSSEmptyView(type: .collectionMine)`의 카피("내 컬렉션이 없어요")가 타유저 맥락에 안 맞는 것도
  이 이유로 감수했다(도달 빈도가 사실상 0이라 전용 카피·타입을 새로 만들 만큼은 아니라고 판단).
- ⚠️ **`#if DEBUG`로 가드한 preview 전용 init을 쓰는 `#Preview`는 그 `#Preview` 블록도 `#if DEBUG`로 감싸야 한다**
  (`CreateCollectionViewModel.init(previewDraft:…)` ↔ `CreateCollectionView`의 `#Preview("작품 포함")`).
  `#Preview` 본문은 **Release 구성에서도 컴파일된다** — CI(Debug 테스트)와 시뮬레이터 Debug 빌드는 통과하는데
  `tuist build`(= `WSS-iOS-RELEASE` 스킴)만 "extra arguments in call"로 깨져, #227 머지 직전 `ready-merge`
  전체 빌드 검증에서야 드러났다(2026-08-29). `#Preview` 안의 명시적 `return` 자체는 문제 없다(다른 모듈에서 통과 확인).
