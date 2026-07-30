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
- **Alert 버튼 탭은 `isPresented`를 자동으로 닫지 않는다**(SwiftUI `.alert`와 다름) — 취소 버튼 포함 **모든 buttonActions가 스스로 표시 상태를 되돌려야** 한다. 안 그러면 알럿이 안 닫힌다.
- **`isPresented`는 그대로 두고 `alertType`만 바뀌는 다단계 알럿**(예: "신고할까요?" 확인 → "신고 접수했습니다" 완료)은 `WSSAlertView`에 `.id(alertType)`를 걸어 뷰 정체성을 갈라야 `.transition`이 실제로 발동한다 — 안 걸면 SwiftUI가 "같은 뷰"로 보고 내용만 즉시 스냅 교체해버려 애니메이션이 없다(`WSSAlertType`을 `Hashable`로 만든 이유). `.animation(value:)`도 `isPresented`뿐 아니라 `alertType` 변화에도 걸어야 이 전환이 애니메이션된다.
- **이미지 + `onTapGesture` 패턴은 접근성 트리에 안 잡힌다**(VoiceOver·UI 자동화 모두) — 탭 가능한 이미지에는 `.accessibilityLabel` + `.accessibilityAddTraits(.isButton)`을 같이 달거나 `Button`을 쓸 것(WSSFeadHeaderView의 프로필·threedots에서 발견).
- **`scaledToFill().frame(...).clipShape(...)`는 그리기만 자르고 hit-test 영역은 스케일된 원본 크기로 남는다** — 프레임보다 세로로 긴 이미지(정사각 이상)면 보이지 않는 터치 영역이 위아래로 넘쳐 **형제 뷰의 버튼 탭을 가로챈다**(WSSFeedImageView가 WSSFeadView 헤더의 프로필·threedots를 죽이던 버그, #154에서 수정). 장식 이미지는 `.allowsHitTesting(false)`, 탭이 필요한 이미지는 clip 뒤 `.contentShape`로 hit 영역을 명시할 것.
- `WSSSearchBar`는 `isFocused: FocusState<Bool>.Binding? = nil`로 외부 포커스 제어를 선택적으로 받는다(기본 nil이면 내부 `@FocusState` 사용). 호출부가 포커스를 직접 제어하려면(자동 포커스, 바깥 탭 시 dismiss 등) 일반 `@State`가 아니라 **자체 `@FocusState` 프로퍼티**를 선언해 그 `$binding`을 넘겨야 한다 — 타입이 `FocusState<Bool>.Binding`이라 `Binding<Bool>`과 호환되지 않는다.
- `WSSFlowLayout.sizeThatFits`는 제안된 폭이 유한하면 내용 실제 폭이 아니라 **그 폭을 그대로** 자기 크기로 보고한다 — 내용이 한 줄을 못 채워도 상위 스택의 기본(가운데) 정렬에 밀려 왼쪽 정렬이 안 보이는 문제를 막기 위한 의도적 선택. 폭 제약이 없을 때만(`.infinity`) 내용 폭에 맞춰 줄어든다.
- `FeedHeader`/`WSSFeedReact`는 콜백(`profileTapped`/`threeDotsButtonTapped`/`likeButtonTapped`)과 `isLiked`를 struct에 담지 않는다 — 각각 `WSSFeadHeaderView`/`WSSFeedReactView` **뷰 레벨** 파라미터로만 받는다(struct는 순수 표시 데이터). 좋아요 아이콘은 `icThumbUp`/`icThumbUpFill`만 쓴다(`icLike`/`icLikeSelected` 에셋 없음). 과거 "콜백 책임 분리" 리팩터(#135/#148)가 이 구조를 몇 번 바꾸려다 접근성 탭 타겟 수정(#154, `.contentShape`+`onTapGesture`+`accessibilityLabel`, 프로필 탭 영역을 닉네임까지 확장)과 반복 충돌했다 — rebase 시 두 설계를 섞지 말고 이 규칙대로 정리할 것.
- `WSSDropdownItem`의 글자색 파라미터명은 `textColor`(구 `titleColor` 아님), 순서는 `title, action, textColor = 기본값`. `textColor`가 기본값을 갖고 `action` 뒤에 오므로 `WSSDropdownItem(title: "x") { ... }` 트레일링 클로저 호출은 그대로 유효 — 단 색을 지정하려면 `action:`/`textColor:` 라벨을 명시해야 한다(트레일링 클로저는 라벨 있는 인자 뒤엔 못 붙음). `NovelDetailFeature`처럼 **다른 Feature 모듈**이 이 컴포넌트를 쓰면 rebase 시 그 호출부도 같이 깨질 수 있으니 시그니처 변경 시 전 레포 검색 필수.
- ⚠️ **`WSSFeadView`는 좋아요 상태/콜백을 하드코딩한 채로 전달한다** — 내부에서 `WSSFeedReactView(react: react, isLiked: true, likeButtonTapped: { print(...) })`를 직접 만들어 쓴다. `WSSFeadView`/`WSSFeedReact`는 실제 `isLiked`/좋아요 콜백을 받는 파라미터가 없어서, 호출부(`NovelDetailFeedTab` 등)가 실제 좋아요 상태·토글을 넘기고 싶어도 지금은 전달 경로가 없다(항상 좋아요된 것처럼 보이고 탭해도 콘솔 출력만 됨). 실제 좋아요 연동이 필요하면 `WSSFeadView`에 `isLiked`/`likeButtonTapped` 파라미터를 추가해 관통시켜야 한다.
