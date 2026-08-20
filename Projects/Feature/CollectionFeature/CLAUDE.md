<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# CollectionFeature

컬렉션(사용자가 작품을 묶어 만드는 목록) 화면. `CollectionDomain`/`CollectionData`(#191)가 먼저 만들어져
있었고, 이 모듈은 그 위에 화면을 얹는 첫 착수(#199, 컬렉션 생성 화면부터).

- 식별자: `ModuleType.feature(.collection)` / 의존: `CollectionDomain`, `BaseDomain`, `DesignSystem`,
  `WSSComponent`, `Logger`
- 진입점: `CollectionFeatureFactory.makeCreateCollectionView(createCollectionUseCase:logger:onAddNovelTapped:onAuthenticationRequired:)`
  (모듈에 화면이 더 늘어날 예정이라 `makeView`가 아니라 화면명을 붙인 이름)

## 핵심 시나리오

- **컬렉션 생성만** — 수정(edit)은 이번 범위 밖. `CreateCollectionViewModel`은 항상 빈 `CollectionDraft()`로
  시작하고(로드 없음), 완료 시 `CreateCollectionUseCase`로 제출 후 자기완결 dismiss.
- **작품은 이 화면에서 추가/제거할 수 없다** — "작품 추가"/"작품 수정" 타일은 `onAddNovelTapped` 콜백만
  발화한다(실제 작품 검색 화면은 후속 이슈). `draft.novelIDs`를 채우는 유일한 경로가 아직 없어, 실제
  앱에서는 작품 리스트 그리드가 항상 빈 상태로만 보인다 — 채워진 그리드 UI 자체는 구현·Preview("작품
  포함")로 검증돼 있다.

## 화면 동작 계약

- **뒤로가기(취소)**: 변경 사항이 없으면 바로 닫히고, 있으면 "컬렉션 생성을 그만하시겠어요?" 확인
  알럿(`WSSAlertType.stopWritingCollection`)을 띄운다 — `NovelReviewFeature`/`FeedFeature`의 "그만 작성"
  패턴과 동일(사용자 확정, #199). 기준선은 항상 빈 `CollectionDraft()`(로드가 없어서).
- **작품 카드(표지 이미지) 셀 전체를 탭하면 그 작품이 대표로 전환**된다(`CollectionDraft.setRepresentativeNovel`)
  — 처음엔 우상단 "대표" 배지만 탭 대상이었으나, 배지만으론 탭 영역이 좁다는 사용자 피드백으로 **셀
  전체**로 넓혔다(#199). 배지는 순수 표시용(대표 여부 뱃지)이라 더는 별도 `Button`이 아니다 — 커버
  이미지를 감싸는 `Button` 하나가 셀 전체 탭을 받는다(중첩 `Button` 금지 — `WSSComponent/CLAUDE.md`).
  제거(삭제)는 이 화면 범위가 아니라 후속 "작품 추가/수정" 화면에서만 가능할 예정.
  대표를 한 번도 안 골라도 제출은 된다 — `effectiveRepresentativeNovelID`가 표시 순서 첫 작품으로
  대신한다(도메인 계약, `CollectionDomain/CLAUDE.md` 참고).
- **"완료" 버튼 활성화 기준은 `draft.isSubmittable`**(이름 비어있지 않음 && 작품 1개 이상)이다 — Figma
  3프레임 모두 "완료" 텍스트가 비활성 회색으로 보이지만(작품까지 채운 프레임도 마찬가지), 이는 목업이
  실제 버튼 상태를 반영하지 않은 것으로 보고 도메인 규칙을 그대로 따른다.
- "작품 추가" 타일 아이콘은 신규 에셋이 아니라 기존 `WSSImage.icBookRegister`를 재사용한다 — 그 SVG의
  내부 레이어명이 Figma 원본과 동일한 `mdi:book-plus-outline`이라 이미 같은 아이콘이 들어있었다.

## 주의사항 (작업 중 발견 시 누적)

- **`CreateCollectionViewModel`에 `#if DEBUG` 전용 `init(previewDraft:previewNovelDisplayInfo:createCollectionUseCase:)`가 있다** —
  작품 리스트 그리드(대표 배지 포함)를 렌더링해 볼 유일한 경로가 Xcode Preview뿐이라(작품 추가 화면이
  없어 실제 앱·Demo 둘 다 도달 불가) 만든 시각 확인용 우회로다. **Factory·프로덕션 코드는 이 init을
  쓰지 않는다** — `CreateCollectionView.swift`의 `#Preview("작품 포함")`에서만 사용.
- ⚠️ **`addNovelTile`과 `novelGridCell`은 같은 그리드 행을 채우므로 커버 박스 사이즈 산정 방식(`novelCoverAspectRatio`)과
  "제목 줄" 유무를 반드시 맞춰야 한다** — 처음엔 `addNovelTile`만 고정 `height: 156`을 썼는데, 옆
  `novelGridCell`은 커버(가변 높이) + 제목 텍스트(최대 2줄)로 총 높이가 더 길어 행이 어긋나 보였다
  (#199 리뷰 피드백). 지금은 둘 다 같은 `aspectRatio`로 커버를 그리고, `addNovelTile`엔 실제 텍스트
  없는 투명 `Text(" ")`(같은 폰트)로 제목 줄 자리만 예약한다. 셀 종류를 늘릴 땐 이 짝을 깨지 말 것.
  - ⚠️ **`.aspectRatio(_, contentMode:)`를 `VStack`(텍스트·아이콘만 있는, `Spacer` 없는) 같은 "내용물이
    작은 뷰"에 직접 걸면 그 뷰가 그리드 칸을 안 채우고 내용물의 자연 크기(이 경우 ~41pt)로 쪼그라든다**
    (실측 — `addNovelTile`을 처음 이 방식으로 고쳤다가 타일이 왼쪽 위에 작게 뜨는 걸 발견, #199). `.frame(maxWidth: .infinity)`를
    앞에 끼워도 높이 방향은 안 채워진다. **`WSSNovelCoverImage`가 쓰는 것과 같은 해법**: `Color.clear`가
    `.aspectRatio`로 비율·크기를 잡고, 실제 콘텐츠는 `.overlay { ... }`로 그 위에 얹는다 — `Color.clear`는
    어떤 제안 크기든 그대로 받아들이므로 aspectRatio가 계산한 박스 전체가 항상 채워진다.
