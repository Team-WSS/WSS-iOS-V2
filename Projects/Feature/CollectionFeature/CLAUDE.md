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
- **작품 카드(표지 이미지) 자체를 탭해도 이 화면에선 아무 반응이 없다**(사용자 확정, #199) — 탭 가능한
  건 "대표" 배지뿐. 제거(삭제)는 이 화면 범위가 아니라 후속 "작품 추가/수정" 화면에서만 가능할 예정.
- **대표 작품 배지를 탭하면 즉시 그 작품이 대표로 전환**된다(`CollectionDraft.setRepresentativeNovel`).
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
