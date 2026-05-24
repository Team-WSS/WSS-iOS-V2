import SwiftUI
import DesignSystem

public struct WSSSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: () -> Void

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        placeholder: String,
        onSearch: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearch = onSearch
    }

    private var isActive: Bool { isFocused || !text.isEmpty }

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
                        .focused($isFocused)
                }
                .padding(.leading, 16)

                Spacer()

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        WSSImage.icCancel.swiftUIImage
                            .frame(width: 36, height: 36)
                    }
                }

                Button(action: onSearch) {
                    WSSImage.icSearch.swiftUIImage
                        .frame(width: 36, height: 36)
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 42)
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
