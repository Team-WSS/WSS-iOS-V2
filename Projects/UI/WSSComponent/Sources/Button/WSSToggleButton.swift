import SwiftUI
import DesignSystem

public struct WSSToggleButton: View {
    @Binding var isOn: Bool

    private let width: CGFloat = 40
    private let height: CGFloat = 22
    private let thumbSize: CGFloat = 18
    private let padding: CGFloat = 2

    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }

    public var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.wssPrimary100 : Color.wssGray100)
                .frame(width: width, height: height)

            Circle()
                .fill(Color.wssWhite)
                .frame(width: thumbSize, height: thumbSize)
                .padding(padding)
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.25, dampingFraction: 1.0), value: isOn)
        .onTapGesture {
            isOn.toggle()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isOn = true
        @State private var isOff = false

        var body: some View {
            HStack(spacing: 24) {
                WSSToggleButton(isOn: $isOn)
                WSSToggleButton(isOn: $isOff)
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
