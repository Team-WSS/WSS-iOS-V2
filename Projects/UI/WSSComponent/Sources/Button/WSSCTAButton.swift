import SwiftUI
import DesignSystem

public struct WSSCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    public init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 53)
        }
        .background(isEnabled ? Color.wssPrimary100 : Color.wssGray70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        WSSCTAButton(title: "해당하는 글 보기") { print("Tap!")}
        WSSCTAButton(title: "비활성 상태", isEnabled: false) { }
    }
    .padding(.horizontal, 16)
}
