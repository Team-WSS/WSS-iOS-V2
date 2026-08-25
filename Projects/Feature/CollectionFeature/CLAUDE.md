<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# CollectionFeature

컬렉션(사용자가 작품을 묶어 만드는 목록) 화면. `CollectionDomain`/`CollectionData`(#191)가 먼저 만들어져
있었고, 이 모듈은 그 위에 화면을 얹는 첫 착수(#199, 컬렉션 생성 화면부터).

- 식별자: `ModuleType.feature(.collection)` / 의존: `CollectionDomain`, `SearchDomain`(작품 검색 —
  "작품 추가" 화면), `NovelDomain`(서재 조회 — "서재에서 추가" 화면, 서재 Domain 코드는 별도 모듈이
  아니라 `NovelDomain`에 있다 — `LibraryFeature`와 같은 이유), `BaseDomain`, `DesignSystem`,
  `WSSComponent`, `Logger`
- 진입점:
  - `CollectionFeatureFactory.makeCreateCollectionView(createCollectionUseCase:searchNovelUseCase:loadMyLibraryUseCase:logger:onAuthenticationRequired:)`
  - `CollectionFeatureFactory.makeCollectionListView(userID:loadCollectionsUseCase:loadLikedCollectionsUseCase:createCollectionUseCase:searchNovelUseCase:loadMyLibraryUseCase:logger:onAuthenticationRequired:)`
  (모듈에 화면이 둘 이상이라 `makeView`가 아니라 화면명을 붙인 이름)

## 핵심 시나리오

- **컬렉션 생성만** — 수정(edit)은 이번 범위 밖. `CreateCollectionViewModel`은 항상 빈 `CollectionDraft()`로
  시작하고(로드 없음), 완료 시 `CreateCollectionUseCase`로 제출 후 자기완결 dismiss.
- **작품 추가/제거는 `CollectionSearchNovelView`(로컬 push, Factory 미노출)에서 이뤄진다** —
  `CreateCollectionView`의 "작품 추가"/"작품 수정" 타일이 push하고, `SearchNovelUseCase`로 검색·
  다중선택한 뒤 "완료"를 누르면 선택 목록 **전체**가 `.setNovels`로 `draft.novelIDs`를 통째로
  교체한다(부분 추가/제거 액션 없음 — 화면을 나갈 때 최종 선택 스냅샷만 반영). 검색 중 골라둔 항목은
  검색어를 바꿔도 별도 상태(`selectedNovels`)로 유지된다. 정원(`CollectionDraft.maxNovelCount`=100)이
  차면 더 담기지 않고 `WSSToastType.selectionOverLimit`로 알린다 — **문구는 범용 텍스트("100개까지
  선택 가능해요")를 임시로 쓰는 중**, 기획팀 확정 문구 전달 예정(2026-08-24). 문구가 오면 `WSSToastType`
  텍스트만 교체하면 된다(구조는 이미 확정).
- **검색 결과 무한스크롤** — `SearchFeature.NormalSearchViewModel`과 동일한 정수 `page`(0부터) 방식.
  `LazyVStack` 마지막 행 `onAppear`에서 `.loadMore`를 발화하고, `CollectionSearchNovelViewModel`이
  `hasNextSearchPage`(서버 `Paginated.hasNext`)가 false가 될 때까지 다음 페이지를 이어붙인다.
- **"서재에서 추가"(`CollectionMyLibrarySelectView`, 로컬 push, Factory 미노출)** — `CollectionSearchNovelView`의
  "서재에서 추가" 버튼이 push. 사용자의 서재를 `LoadMyLibraryUseCase`(필터 없음, `MyLibraryFilter()`
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
  세그먼트 탭(`CollectionSegmentedTab`, 로컬)으로 전환. 마이페이지 "컬렉션 N개" 행에서 진입(#200,
  `UserPageFeature`가 콜백만 노출 — 두 Feature는 서로 import 못 해 실제 화면 전환은 App 몫).
  `LoadCollectionsUseCase`(userID 필수)/`LoadLikedCollectionsUseCase`(userID 불필요, 세션 토큰 기준)를
  탭마다 독립된 커서+generation 부기로 lazy 로드한다 — 처음 그 탭을 볼 때만 첫 페이지를 요청하고, 이미
  본 탭은 오갈 때마다 재요청하지 않는다(`CollectionListViewModel`, `CollectionMyLibrarySelectViewModel`의
  패턴을 탭 2개로 확장). "내 컬렉션" 탭에서만 "컬렉션 만들기" 버튼이 보이고, 탭하면 같은 모듈의 기존
  `CreateCollectionView`로 push한다 — 그 화면은 성공 콜백이 없는 계약이라(자기완결 dismiss만) 복귀 시
  성공 여부와 무관하게 무조건 `.mine` 탭을 다시 로드한다. 카드 표지 스택은 `CollectionCoverStackView`
  (로컬) — 마이페이지 미리보기(`UserPageFeature.CollectionSection`, 대표 표지 1장)와는 시각 패턴이
  달라 별개 컴포넌트다. **표지 슬롯은 실제 작품 수(1~5)와 무관하게 항상 5칸**이다(사용자 확정,
  2026-08-21) — `recentNovels`가 5개 미만이면 남는 슬롯을 `WSSNovelCoverImage(url: nil)`의 기본 표지
  폴백으로 채운다("몇 개 들었나"를 표지 개수로 세지 않게 하려는 의도, 작품 수는 카드 부제 `작품 N`으로만
  알린다). 오버플로 배지("+N")는 없다 — Figma 목업의 숫자 배지는 실제 컴포넌트가 아니라 더미 데이터의
  잔재였다(사용자 확정).

## 화면 동작 계약

- **뒤로가기(취소)**: 변경 사항이 없으면 바로 닫히고, 있으면 "컬렉션 생성을 그만하시겠어요?" 확인
  알럿(`WSSAlertType.stopWritingCollection`)을 띄운다 — `NovelReviewFeature`/`FeedFeature`의 "그만 작성"
  패턴과 동일(사용자 확정, #199). 기준선은 항상 빈 `CollectionDraft()`(로드가 없어서).
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

## 주의사항 (작업 중 발견 시 누적)

- **`CollectionListViewModel`은 표준 VM 섹션 순서(`Feature/CLAUDE.md`) 끝에 `// MARK: - Tab Bookkeeping
  Access`를 추가로 둔다** — 탭 2개(`.mine`/`.liked`)를 동시에 부기해야 하는 첫 사례라, 그 접근자
  헬퍼(`bookkeeping(for:)`/`content(for:)`/`update...`)가 기존 6개 섹션 어디에도 자연스럽게 안
  맞는다. 새 화면에서 같은 "여러 하위상태를 키로 나눠 관리" 패턴이 또 필요하면 이 예외를 정본으로
  삼아도 된다 — 단, 섹션을 늘리는 걸 기본값으로 삼지 말고 정말 기존 섹션에 안 맞을 때만.
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
- ⚠️ **2단계 pop("서재에서 추가" 확정 → `CreateCollectionView`까지)은 중간 화면들이 각자
  `dismiss()`를 부르지 않고, 최상위(`CreateCollectionView`)가 소유한 단 하나의 `isAddNovelPresented`를
  확정 콜백(`onConfirm`) 안에서 딱 한 번만 false로 내려 서브트리 전체를 한 번에 걷어낸다(정본,
  `CreateCollectionView.swift`/`CollectionSearchNovelView.swift`/`CollectionMyLibrarySelectView.swift`
  참고)** — `onConfirm`을 `CreateCollectionView → CollectionSearchNovelView → CollectionMyLibrarySelectView`
  까지 그대로 재사용해 내려보내고, 확정 시 그 콜백이 novels를 `.setNovels`로 반영함과 동시에
  `isAddNovelPresented = false`도 함께 실행한다. 중간 화면(`CollectionSearchNovelView`/
  `CollectionMyLibrarySelectView`)의 확정 핸들러는 `onConfirm(...)` 호출만 하고 자기 자신의
  `dismiss()`는 부르지 않는다 — `isAddNovelPresented`가 그 화면들을 포함한 서브트리를 통째로 pop해준다.
  ⚠️ **이전엔 "자식이 스스로 pop → 부모가 `onChange`로 그 완료를 감지해 뒤이어 pop"하는 계단식
  2회 `dismiss()` 방식(`isPendingDismissAfterMyLibrarySelect` 플래그)을 썼었다** — 그건 "자식의
  `dismiss()`와 부모의 `dismiss()`를 같은 프레임에서 함께 부르면 부모가 pop되지 않는다"는 실측 버그를
  피하려는 것이었는데, 정작 그 계단식 2회 pop 자체가 **두 전환 애니메이션이 거의 같은 프레임에 겹쳐
  보여 "추가" 탭 후 화면이 이중으로 dismiss되는 것처럼 보이는** 새 문제를 냈다(사용자 리포트). 지금의
  "최상위 boolean 한 번만 내리기" 방식은 애초에 pop이 한 번만 발생하므로 이 겹침 문제 자체가 생기지
  않는다 — 계단식 방식으로 되돌리지 말 것.
  ⚠️ **폐기한 대안 둘 다 다른 이유로 깨졌다(2026-08-24 실측)** — 지금 방식과 달리 **둘 다 화면 간
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
  `dismiss()`를 유지하고, 확정만 콜백을 타고 최상위까지 올라가 그쪽의 단일 boolean을 내리는 지금
  패턴**이 유일하게 검증된 정본이다 — 형제 Bool 교체나 중첩 `NavigationStack`으로 "더 깔끔하게" 다시
  풀어보려 하지 말 것(둘 다 이미 실측으로 폐기됨).
- ⚠️ **iOS 18.1 시뮬레이터 런타임에서 `CollectionSearchNovelView`로 push하면 진입 즉시 CPU 100%
  무한 리렌더(AttributeGraph 루프)에 빠진다 — 앱·이 화면의 버그가 아니라 그 OS 런타임 한정 SwiftUI
  회귀로 확인됨.** 같은 빌드 산출물을 iOS 26 시뮬레이터에 설치해 동일 자동화 경로로 재현했을 땐 CPU
  0%로 정상 동작했다(화면 전환·"서재에서 추가"·대표 배지까지 전부 정상). 이 화면을 시뮬레이터에서
  검증할 땐 **iOS 18.1을 피하고 최신 iOS 런타임 시뮬레이터를 쓸 것** — CPU가 진입 직후 100%에 붙박이면
  코드가 아니라 시뮬레이터 런타임부터 의심할 것.
- ⚠️ **로컬 push 화면(Factory에 안 뜨는 "작품 추가"/"서재에서 추가")은 `logger`가 자동으로 안 흐른다 —
  화면마다 파라미터로 직접 받아 다음 화면에 넘겨야 한다(PR #199 리뷰에서 실제로 놓쳤다 발견).**
  `CollectionFeatureFactory`가 `CreateCollectionViewModel`에는 `logger`를 넘겨도, `CreateCollectionView`
  자신의 `init`에 `logger` 파라미터가 없으면 그 화면이 만드는 `CollectionSearchNovelViewModel`은
  기본값 `nil`로 조용히 굳는다 — 컴파일 에러 없이 로그만 사라져서 리뷰 전까진 못 잡았다. 이 모듈처럼
  화면이 화면을 로컬로 여러 단 push하면, **매 단(View 자신 + 그 View가 만드는 다음 VM/View)마다**
  `logger: Logger? = nil` 파라미터를 두고 받은 값을 그대로 내려보내야 체인 끝까지 살아있다.
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
