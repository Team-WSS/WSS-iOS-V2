# View 표준 구조 — 골격 템플릿

새 Feature View를 만들 때 여는 골격. **아래 `// MARK:` 순서·역할을 그대로 따른다.**
규칙("코드만 봐선 모르는 것" — 간격·표시상태 소유·contentShape 트랩 등)은 [../CLAUDE.md](../CLAUDE.md)의 "View 표준 구조" 절에 있다.
정본 레퍼런스: `NovelReviewView`(툴바·섹션·Presentation 풀세트) / `ReadingPeriodSheet`(시트, 툴바 없는 변형).

```swift
import SwiftUI

import BaseDomain
import DesignSystem
import SomeDomain
import WSSComponent

// 화면 책임 한 줄. "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct XxxView: View {

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: XxxViewModel           // @Observable VM은 @State로(@StateObject ❌)
    @State private var isSomeSheetPresented = false       // VM이 처리할 필요 없는 순수 View 표시 상태만 @State
    @Environment(\.dismiss) private var dismiss
    private let title: String                             // 진입 이전 화면이 주입

    init(viewModel: XxxViewModel, title: String) {
        self._viewModel = State(initialValue: viewModel)
        self.title = title
    }

    // body = 조립 + 화면 modifier만(navigation/toolbar/sheet/alert/toast/onAppear/onChange).
    // 실제 레이아웃은 content로 분리.
    var body: some View {
        content
            .toolbar { toolbarContent }
            .onAppear { viewModel.handle(.load) }           // 생명주기도 액션
            .sheet(isPresented: $isSomeSheetPresented) { /* ... */ }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldDismiss) { _, v in if v { dismiss() } }
    }

    // 레이아웃 + 공용 leaf
    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {                            // stack spacing은 항상 0
                someSection
                Spacer().frame(height: 24)                 // 고정 간격은 Spacer().frame으로
                otherSection
            }
        }
    }
}

// MARK: - Toolbar
// 툴바 내용물은 @ToolbarContentBuilder 분리 프로퍼티로. body엔 `.toolbar { toolbarContent }`만.
private extension XxxView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent { /* ToolbarItem들 */ }
}

// MARK: - Sections
// 섹션은 var xxxSection: some View. 각 섹션에 의도/함정 doc comment.
private extension XxxView { /* var someSection: some View { ... } */ }

// MARK: - Presentation
// 의미값(VM enum) → 컴포넌트 타입/카피/색 매퍼 + VM이 소유한 표시상태 Binding(get:set:)(set은 handle 경유).
private extension XxxView {
    var toastBinding: Binding<Bool> {
        Binding(get: { viewModel.state.presentedError != nil },
                set: { if !$0 { viewModel.handle(.dismissError) } })
    }
    var toastType: WSSToastType { /* state.presentedError → 토스트 타입 */ }
}

// MARK: - Preview
// #Preview는 Sources 내부(internal). mock UseCase는 private.
```
