import SwiftUI
import DesignSystem

public struct WSSSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: () -> Void
    /// 텍스트를 비우는 x 버튼(`icCancel`)을 탭했을 때 추가로 호출된다. 검색 취소·이전 화면 복귀 등
    /// 호출부가 텍스트 초기화 이상의 반응이 필요할 때만 넘긴다(기본 nil이면 텍스트만 비움).
    let onCancel: (() -> Void)?
    let externalFocus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    public init(
        text: Binding<String>,
        placeholder: String,
        isFocused: FocusState<Bool>.Binding? = nil,
        onSearch: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.externalFocus = isFocused
        self.onSearch = onSearch
        self.onCancel = onCancel
    }

    private var isActive: Bool { (externalFocus?.wrappedValue ?? internalFocus) || !text.isEmpty }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.wssWhite : Color.wssGray50)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? Color.wssGray70 : Color.clear, lineWidth: 1)
                )

            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .applyWSSFont(.label1)
                            .foregroundStyle(Color.wssGray200)
                    }
                    TextField("", text: $text)
                        .applyWSSFont(.label1)
                        .foregroundStyle(Color.wssBlack)
                        .focused(externalFocus ?? $internalFocus)
                        .submitLabel(.search)
                        .onSubmit(onSearch)
                }
                .padding(.leading, 16)

                Spacer()

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onCancel?()
                    }) {
                        WSSImage.icCancel.swiftUIImage
                            .frame(width: 36, height: 36)
                    }
                }

                Button(action: {
                    dismissKeyboard()
                    onSearch()
                }) {
                    WSSImage.icSearch.swiftUIImage
                        .frame(width: 36, height: 36)
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 42)
    }

    private func dismissKeyboard() {
        if let externalFocus {
            externalFocus.wrappedValue = false
        } else {
            internalFocus = false
        }
    }
}

#Preview {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = "검색어"

    VStack(spacing: 16) {
        WSSSearchBar(text: $text1, placeholder: "작품 제목, 작가를 검색하세요") {
            print("검색!")
        }
        WSSSearchBar(text: $text2, placeholder: "작품 제목, 작가를 검색하세요") {
            print("검색!")
        }
    }
    .padding(.horizontal, 16)
}
