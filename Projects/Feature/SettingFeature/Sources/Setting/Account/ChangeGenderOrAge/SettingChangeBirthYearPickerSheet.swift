//
//  SettingChangeBirthYearPickerSheet.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

struct SettingChangeBirthYearPickerSheet: View {

    @Binding var selectedYear: Int
    @State private var draftYear: Int
    @State private var contentHeight: CGFloat = 300
    @Environment(\.dismiss) private var dismiss

    init(selectedYear: Binding<Int>) {
        self._selectedYear = selectedYear
        self._draftYear = State(initialValue: selectedYear.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("출생연도")
                    .applyWSSFont(.title1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    WSSImage.icCancelModal.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                        .frame(width: 65, height: 65)
                }
            }
            .padding(.leading, 25)

            SettingBirthYearWheel(year: $draftYear)

            Spacer().frame(height: 20)

            WSSCTAButton(title: "완료",
                         action: {
                selectedYear = draftYear
                dismiss()
            })
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: SheetContentHeightKey.self,
                                       value: proxy.size.height)
            }
        )
        .onPreferenceChange(SheetContentHeightKey.self) { newValue in
            guard newValue > 0 else { return }
            contentHeight = newValue
        }
        .presentationDetents([.height(contentHeight)])
        .presentationBackground(WSSColor.wssWhite.swiftUIColor)
        .interactiveDismissDisabled()
    }
}

/// 시트 콘텐츠의 실측 높이를 부모로 끌어올리기 위한 PreferenceKey.
private struct SheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    SettingChangeBirthYearPickerSheet(selectedYear: .constant(2001))
}
