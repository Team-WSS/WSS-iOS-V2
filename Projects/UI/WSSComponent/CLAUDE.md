<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/UI/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# WSSComponent

웹소소 공용 SwiftUI 컴포넌트 — Alert, Toast, Button, FeedCell, SearchBar 등.

- 식별자: `ModuleType.ui(.wssComponent)` / 의존: SwiftUI, `DesignSystem`, `BaseDomain`

## 패턴

- **오버레이 UI(Alert/Toast)는 `ViewModifier` + `@Binding isPresented` + `View+` 확장**으로 제공. 예: `WSSAlertViewModifier`는 `isPresented`일 때 딤(`Color.black.opacity(0.6)`) + 알럿을 overlay, 전환 애니메이션 포함. 버튼 동작은 `buttonActions: [() -> Void]` 배열로 주입.
- 스타일/타입은 enum으로 분리 (`WSSAlertType`/`WSSAlertStyle`, `WSSToastType`/`WSSToastStyle`).
- 색·폰트는 전부 `DesignSystem` 토큰 사용.

## 주의사항 (작업 중 발견 시 누적)

- 컴포넌트가 아는 도메인은 **`BaseDomain`의 공통 값 타입까지**(`ReadingStatus`, `AttractivePoint`, `NovelGenre`, `SortType` 등). 이들의 라벨·색·아이콘 매핑을 `Sources/DomainPresentation/`(`+Presentation` 확장, public)에 한곳으로 모아 Feature가 중복 매핑하지 않게 한다. → 그 외 도메인 Entity·Repository나 상위 Feature 모델은 모른다(표시 데이터/콜백만 값으로 받음).
- Alert 버튼은 인덱스 기반 `buttonActions` 배열 ↔ 버튼 개수 매칭에 주의.
