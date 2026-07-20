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
- 특정 화면 전용 **필터용 값 목록**(예: `NovelGenre.myFeedFilter`, 검색 화면 장르 그리드용 `NovelGenre.searchGenre`)도 라벨·색 매핑과 동일하게 `DomainPresentation` 확장에 둔다 — `BaseDomain`은 순수 enum만 갖고 화면별 부분집합/순서는 여기서 정의. `myFeedFilter`와 `searchGenre`는 **의도적으로 다른 순서**의 별개 목록 — 한쪽을 고친다고 다른 쪽까지 맞추지 말 것.
- Alert 버튼은 인덱스 기반 `buttonActions` 배열 ↔ 버튼 개수 매칭에 주의.
- **Alert 버튼 탭은 `isPresented`를 자동으로 닫지 않는다**(SwiftUI `.alert`와 다름) — 취소 버튼 포함 **모든 buttonActions가 스스로 표시 상태를 되돌려야** 한다. 안 그러면 알럿이 안 닫힌다.
- **`isPresented`는 그대로 두고 `alertType`만 바뀌는 다단계 알럿**(예: "신고할까요?" 확인 → "신고 접수했습니다" 완료)은 `WSSAlertView`에 `.id(alertType)`를 걸어 뷰 정체성을 갈라야 `.transition`이 실제로 발동한다 — 안 걸면 SwiftUI가 "같은 뷰"로 보고 내용만 즉시 스냅 교체해버려 애니메이션이 없다(`WSSAlertType`을 `Hashable`로 만든 이유). `.animation(value:)`도 `isPresented`뿐 아니라 `alertType` 변화에도 걸어야 이 전환이 애니메이션된다.
- **이미지 + `onTapGesture` 패턴은 접근성 트리에 안 잡힌다**(VoiceOver·UI 자동화 모두) — 탭 가능한 이미지에는 `.accessibilityLabel` + `.accessibilityAddTraits(.isButton)`을 같이 달거나 `Button`을 쓸 것(WSSFeadHeaderView의 프로필·threedots에서 발견).
- **`scaledToFill().frame(...).clipShape(...)`는 그리기만 자르고 hit-test 영역은 스케일된 원본 크기로 남는다** — 프레임보다 세로로 긴 이미지(정사각 이상)면 보이지 않는 터치 영역이 위아래로 넘쳐 **형제 뷰의 버튼 탭을 가로챈다**(WSSFeedImageView가 WSSFeadView 헤더의 프로필·threedots를 죽이던 버그, #154에서 수정). 장식 이미지는 `.allowsHitTesting(false)`, 탭이 필요한 이미지는 clip 뒤 `.contentShape`로 hit 영역을 명시할 것.
- `WSSSearchBar`는 `isFocused: FocusState<Bool>.Binding? = nil`로 외부 포커스 제어를 선택적으로 받는다(기본 nil이면 내부 `@FocusState` 사용). 호출부가 포커스를 직접 제어하려면(자동 포커스, 바깥 탭 시 dismiss 등) 일반 `@State`가 아니라 **자체 `@FocusState` 프로퍼티**를 선언해 그 `$binding`을 넘겨야 한다 — 타입이 `FocusState<Bool>.Binding`이라 `Binding<Bool>`과 호환되지 않는다.
- `WSSFlowLayout.sizeThatFits`는 제안된 폭이 유한하면 내용 실제 폭이 아니라 **그 폭을 그대로** 자기 크기로 보고한다 — 내용이 한 줄을 못 채워도 상위 스택의 기본(가운데) 정렬에 밀려 왼쪽 정렬이 안 보이는 문제를 막기 위한 의도적 선택. 폭 제약이 없을 때만(`.infinity`) 내용 폭에 맞춰 줄어든다.
- `FeedHeader`/`WSSFeedReact`는 콜백(`profileTapped`/`threeDotsButtonTapped`/`likeButtonTapped`)과 `isLiked`를 struct에 담지 않는다 — 각각 `WSSFeadHeaderView`/`WSSFeedReactView` **뷰 레벨** 파라미터로만 받는다(struct는 순수 표시 데이터). 좋아요 아이콘은 `icThumbUp`/`icThumbUpFill`만 쓴다(`icLike`/`icLikeSelected` 에셋 없음). 과거 "콜백 책임 분리" 리팩터(#135/#148)가 이 구조를 몇 번 바꾸려다 접근성 탭 타겟 수정(#154, `.contentShape`+`onTapGesture`+`accessibilityLabel`, 프로필 탭 영역을 닉네임까지 확장)과 반복 충돌했다 — rebase 시 두 설계를 섞지 말고 이 규칙대로 정리할 것.
- `WSSDropdownItem`의 글자색 파라미터명은 `textColor`(구 `titleColor` 아님), 순서는 `title, action, textColor = 기본값`. `textColor`가 기본값을 갖고 `action` 뒤에 오므로 `WSSDropdownItem(title: "x") { ... }` 트레일링 클로저 호출은 그대로 유효 — 단 색을 지정하려면 `action:`/`textColor:` 라벨을 명시해야 한다(트레일링 클로저는 라벨 있는 인자 뒤엔 못 붙음). `NovelDetailFeature`처럼 **다른 Feature 모듈**이 이 컴포넌트를 쓰면 rebase 시 그 호출부도 같이 깨질 수 있으니 시그니처 변경 시 전 레포 검색 필수.
- `WSSFeadView`는 `isLiked`/`likeButtonTapped`를 자체 파라미터로 받아 `WSSFeedReactView`에 그대로 넘긴다(둘 다 기본값 없는 필수 파라미터 — 호출부가 실제 좋아요 상태/토글을 직접 채워야 한다).
- `WSSFeedImageView`처럼 `AsyncImage`의 여러 `phase`(`.success`/`.failure`)에 이미지를 그릴 땐 **각 phase의 이미지마다 개별적으로 `.resizable()`을 걸어야** 바깥에 얹은 `.scaledToFill()`/`.frame`이 실제로 적용된다 — 하나라도 빠뜨리면 그 phase(예: 로드 실패 placeholder)만 조용히 원본 크기로 나온다.
- `WSSSortButton`처럼 `Button` 라벨 안의 값(예: `sortType`에 따른 텍스트/아이콘)이 바뀌는 경우, 호출부에 별도 `.animation`이 없어도 탭 트랜잭션에 얹혀 암시적으로 크로스페이드된다. 즉시 전환을 원하면 그 값에 `.animation(nil, value:)`를 명시해야 한다.
- `WSSFeadView`의 `isSpoiler`/`isPrivate`는 단순 배지가 아니라 **하위 콘텐츠를 통째로 대체**한다: `isSpoiler: true`면 `content` 텍스트가 "스포일러가 포함된 글 보기"로, `feedImage`가 있어도 이미지 자체가 렌더링되지 않는다. `isPrivate: true`면 `react`(좋아요/댓글) 섹션이 아예 안 뜨고 "나만 보는 기록이에요." 행으로 대체된다 — 호출부가 `react`를 넘겨도 private일 땐 좋아요/댓글 버튼에 접근할 수 없다.
- `HapticManager`(`Sources/Haptic/`)는 Core가 아니라 여기 있다 — 도메인 지식이 없는 순수 기술이라 Core 기준(재사용 가능한 기반 기술)에도 맞지만, 등록된 `CoreModule`에 범용 유틸 모듈이 없고(`Keychain`/`Networking`/`Logger`만 존재) 이걸 위해 새 Core 모듈을 만들 정도는 아니라고 판단해 WSSComponent에 뒀다. 호출은 자동 적용되지 않고 **각 콜사이트가 상황에 맞는 스타일을 직접 골라 명시적으로 호출**해야 한다(예: `WSSSortButton` action 클로저 안에서 `HapticManager.selection()`).
- Capsule 모양 칩/버튼의 배경·테두리는 `.background(Color).clipShape(Capsule()).overlay(Capsule().stroke(...))` 대신 `.background { Capsule().fill(...) }.overlay { Capsule().strokeBorder(...) }` 패턴을 쓰면 clipShape가 불필요해지고(도형이 이미 캡슐로만 그려짐) `strokeBorder`는 테두리가 프레임 안쪽으로만 그려져 `stroke`처럼 경계 밖으로 살짝 번지지 않는다. `WhiteRemovableKeywordChip`은 이 패턴으로 전환됨, `PrimaryRemovableKeywordChip`/`WSSFilterButton`은 아직 구 패턴 — 새로 만들 때는 신 패턴을 우선한다.
