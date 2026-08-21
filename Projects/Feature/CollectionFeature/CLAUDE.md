<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# CollectionFeature

컬렉션(사용자가 작품을 묶어 만드는 목록) 화면. `CollectionDomain`/`CollectionData`(#191)가 먼저 만들어져
있었고, 이 모듈은 그 위에 화면을 얹는 첫 착수(#199, 컬렉션 생성 화면부터).

- 식별자: `ModuleType.feature(.collection)` / 의존: `CollectionDomain`, `SearchDomain`(작품 검색 —
  "작품 추가" 화면), `BaseDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `CollectionFeatureFactory.makeCreateCollectionView(createCollectionUseCase:searchNovelUseCase:logger:onAuthenticationRequired:)`
  (모듈에 화면이 더 늘어날 예정이라 `makeView`가 아니라 화면명을 붙인 이름)

## 핵심 시나리오

- **컬렉션 생성만** — 수정(edit)은 이번 범위 밖. `CreateCollectionViewModel`은 항상 빈 `CollectionDraft()`로
  시작하고(로드 없음), 완료 시 `CreateCollectionUseCase`로 제출 후 자기완결 dismiss.
- **작품 추가/제거는 `AddNovelView`(로컬 push, Factory 미노출)에서 이뤄진다** — `CreateCollectionView`의
  "작품 추가"/"작품 수정" 타일이 push하고, `SearchNovelUseCase`로 검색·다중선택한 뒤 "완료"를 누르면
  선택 목록 **전체**가 `.setNovels`로 `draft.novelIDs`를 통째로 교체한다(부분 추가/제거 액션 없음 —
  화면을 나갈 때 최종 선택 스냅샷만 반영). 검색 중 골라둔 항목은 검색어를 바꿔도 별도 상태
  (`selectedNovels`)로 유지된다. 정원(`CollectionDraft.maxNovelCount`=100)이 차면 더 담기지 않지만
  아직 별도 피드백(토스트 등)은 없다(3B 미결).
- **검색 결과 무한스크롤** — `SearchFeature.NormalSearchViewModel`과 동일한 정수 `page`(0부터) 방식.
  `LazyVStack` 마지막 행 `onAppear`에서 `.loadMore`를 발화하고, `AddNovelViewModel`이 `hasNextSearchPage`
  (서버 `Paginated.hasNext`)가 false가 될 때까지 다음 페이지를 이어붙인다.

## 화면 동작 계약

- **뒤로가기(취소)**: 변경 사항이 없으면 바로 닫히고, 있으면 "컬렉션 생성을 그만하시겠어요?" 확인
  알럿(`WSSAlertType.stopWritingCollection`)을 띄운다 — `NovelReviewFeature`/`FeedFeature`의 "그만 작성"
  패턴과 동일(사용자 확정, #199). 기준선은 항상 빈 `CollectionDraft()`(로드가 없어서).
- **작품 카드(표지 이미지) 셀 전체를 탭하면 그 작품이 대표로 전환**된다(`CollectionDraft.setRepresentativeNovel`)
  — 처음엔 우상단 "대표" 배지만 탭 대상이었으나, 배지만으론 탭 영역이 좁다는 사용자 피드백으로 **셀
  전체**로 넓혔다(#199). 배지는 순수 표시용(대표 여부 뱃지)이라 더는 별도 `Button`이 아니다 — 커버
  이미지를 감싸는 `Button` 하나가 셀 전체 탭을 받는다(중첩 `Button` 금지 — `WSSComponent/CLAUDE.md`).
  제거(삭제)는 이 화면 범위가 아니라 `AddNovelView`("작품 추가/수정" 화면)에서만 가능하다 — 그 화면의
  작품 행을 다시 탭해 선택 해제하고 "완료"로 확정하면 이 그리드에서도 빠진다.
  대표를 한 번도 안 골라도 제출은 된다 — `effectiveRepresentativeNovelID`가 표시 순서 첫 작품으로
  대신한다(도메인 계약, `CollectionDomain/CLAUDE.md` 참고).
- **"완료" 버튼 활성화 기준은 `draft.isSubmittable`**(이름 비어있지 않음 && 작품 1개 이상)이다 — Figma
  3프레임 모두 "완료" 텍스트가 비활성 회색으로 보이지만(작품까지 채운 프레임도 마찬가지), 이는 목업이
  실제 버튼 상태를 반영하지 않은 것으로 보고 도메인 규칙을 그대로 따른다.
- "작품 추가" 타일 아이콘은 신규 에셋이 아니라 기존 `WSSImage.icBookRegister`를 재사용한다 — 그 SVG의
  내부 레이어명이 Figma 원본과 동일한 `mdi:book-plus-outline`이라 이미 같은 아이콘이 들어있었다.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`AddNovelViewModel`의 검색 결과 영역은 `searchedNovels`가 아니라 `hasSearched` 플래그로 가른다** —
  `WSSSearchBar`의 `onSearch`는 제출(엔터/검색 버튼)에만 발화하고, 타이핑 자체는 `updateSearchText`로
  매 글자마다 바로 반영된다. `searchedNovels`(또는 `searchText`) 유무만으로 "결과 없음" 뷰를 켜면,
  검색을 실행하기도 전에(타이핑 도중) 또는 이전 검색 결과를 두고 다음 검색어를 입력하는 도중에 잘못된
  뷰(결과없음/직전 결과)가 보인다(실제 발생 — 사용자 리포트: 타이핑 중엔 흰 배경이어야 함).
  `updateSearchText`가 매번 `hasSearched = false`로 끄고, `searchNovels(_:)`가 응답을 **실제로 받은
  뒤에만** `hasSearched = true`로 켠다 — `resultArea`는 `!hasSearched`면 무조건 빈 화면, 그 다음에야
  `searchedNovels` 유무로 리스트/결과없음을 가른다. `FeedFeature`의 `CreateFeedConnectNovelSheet`도
  같은 검색 흐름(같은 `WSSNovelSelectRow` 기반)을 쓰는데 거긴 `hasSearched`를 검색 제출 시 켜기만 하고
  텍스트 편집 시 끄지 않아 — 결과를 받은 뒤 재입력하면 이 화면과 달리 직전 결과가 남을 수 있다(이번
  변경 범위 밖이라 손대지 않음, 재발 시 여기 패턴 참고).
- **`CreateCollectionViewModel`에 `#if DEBUG` 전용 `init(previewDraft:previewNovelDisplayInfo:createCollectionUseCase:)`가 있다** —
  `AddNovelView`가 생기기 전, 작품 리스트 그리드(대표 배지 포함)를 볼 유일한 경로가 Xcode Preview뿐이던
  시절 만든 시각 확인용 우회로다. 지금은 Demo 앱에서도 "작품 추가" → 검색·선택 → "완료"로 실제 채워볼
  수 있지만, 이 init은 여전히 **Preview 전용**으로 남겨둔다(다른 셀 배치를 즉시 볼 수 있어 유용) —
  **Factory·프로덕션 코드는 쓰지 않는다**. `CreateCollectionView.swift`의 `#Preview("작품 포함")`에서만 사용.
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
