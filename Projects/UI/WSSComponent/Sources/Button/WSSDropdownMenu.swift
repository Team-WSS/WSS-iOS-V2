import SwiftUI
import DesignSystem

public struct WSSDropdownItem {
    public let title: String
    /// 항목 글자색 — 기본 검정, 신고류 항목은 `Color.wssSecondary100`(빨강).
    public let titleColor: Color
    public let action: () -> Void

    public init(title: String,
                titleColor: Color = Color.wssBlack,
                action: @escaping () -> Void) {
        self.title = title
        self.titleColor = titleColor
        self.action = action
    }
}

public struct WSSDropdownMenu: View {
    let items: [WSSDropdownItem]

    public init(items: [WSSDropdownItem]) {
        self.items = Array(items.prefix(2))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                dropdownCell(item: items[index], showDivider: index < items.count - 1)
            }
        }
        .background(Color.wssWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: Color.wssBlack.opacity(0.11),
            radius: 15,
            x: 0,
            y: 2
        )
    }

    private func dropdownCell(item: WSSDropdownItem, showDivider: Bool) -> some View {
        Button(action: item.action) {
            VStack(spacing: 0) {
                Text(item.title)
                    .applyWSSFont(.body2)
                    .foregroundStyle(item.titleColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)

                if showDivider {
                    Color.wssGray50
                        .frame(height: 0.7)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WSSDropdownMenu(items: [
            WSSDropdownItem(title: "수정하기") { print("수정") },
            WSSDropdownItem(title: "삭제하기") { print("삭제") }
        ])
        .frame(width: 160)

        WSSDropdownMenu(items: [
            WSSDropdownItem(title: "차단하기") { print("차단") }
        ])
        .frame(width: 200)
    }
    .padding()
}
