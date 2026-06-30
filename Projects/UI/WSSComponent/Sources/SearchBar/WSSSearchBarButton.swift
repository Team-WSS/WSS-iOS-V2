import SwiftUI
import DesignSystem

/// 검색바처럼 생겼지만 실제 입력은 없는 **탭 버튼**.
/// 탭하면 `action`이 불린다(예: 키워드 탐색 화면으로 이동). `WSSSearchBar`와 달리 `TextField`가 없다.
public struct WSSSearchBarButton: View {

    public enum PlaceholderAlignment {
        case leading
        case center
    }

    private let placeholder: String
    private let placeholderAlignment: PlaceholderAlignment
    private let action: () -> Void

    public init(
        placeholder: String,
        placeholderAlignment: PlaceholderAlignment = .leading,
        action: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self.placeholderAlignment = placeholderAlignment
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.wssGray50)

                Text(placeholder)
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssGray200)
                    .frame(maxWidth: .infinity, alignment: textAlignment)
                    .padding(.horizontal, 16)

                HStack {
                    Spacer()
                    WSSImage.icSearch.swiftUIImage
                        .frame(width: 36, height: 36)
                        .padding(.trailing, 10)
                }
            }
            .frame(height: 42)
            .contentShape(Rectangle()) // 빈 영역까지 전체를 탭 대상으로
        }
        .buttonStyle(.plain)
    }

    private var textAlignment: Alignment {
        switch placeholderAlignment {
        case .leading: .leading
        case .center:  .center
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        WSSSearchBarButton(placeholder: "키워드를 선택하세요") {
            print("탭!")
        }
        WSSSearchBarButton(
            placeholder: "키워드를 선택하세요",
            placeholderAlignment: .center
        ) {
            print("탭!")
        }
    }
    .padding(.horizontal, 16)
}
