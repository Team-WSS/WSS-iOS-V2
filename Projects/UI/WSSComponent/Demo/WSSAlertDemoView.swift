//
//  WSSAlertDemoView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import WSSComponent

struct WSSAlertDemoView: View {
    @State private var showAlert = false
    @State private var selectedType: WSSAlertType = .needTermsAgreement

    var body: some View {
        List(WSSAlertType.allCases, id: \.self) { type in
            Button(String(describing: type)) {
                selectedType = type
                showAlert = true
            }
        }
        .showWSSAlert(isPresented: $showAlert,
                      type: selectedType)
        .overlay(alignment: .bottom) {
            if showAlert {
                Button("닫기") {
                    showAlert = false
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(radius: 4)
                .padding(.bottom, 60)
            }
        }
    }
}
