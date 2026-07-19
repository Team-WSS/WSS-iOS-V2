//
//  SettingChangeBirthYearPickerSheet.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import ProfileDomain

import DesignSystem
import WSSComponent

struct SettingChangeBirthYearPickerSheet: View {

    @Binding var selectedYear: Int
    @State private var draftYear: Int
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

            WSSBirthYearWheel(year: $draftYear,
                              minYear: BirthYear.minYear,
                              maxYear: BirthYear.maxYear)

            Spacer().frame(height: 20)

            WSSCTAButton(title: "완료",
                         action: {
                selectedYear = draftYear
                dismiss()
            })
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .presentationDetents([.height(300)])
        .presentationBackground(WSSColor.wssWhite.swiftUIColor)
        .interactiveDismissDisabled()
    }
}

#Preview {
    SettingChangeBirthYearPickerSheet(selectedYear: .constant(2001))
}
