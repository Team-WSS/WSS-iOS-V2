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
                      type: selectedType,
                      buttonActions: [
                        {
                            showAlert = false
                            print("첫번째 버튼 클릭")
                        },
                        {
                            showAlert = false
                            print("두번째 버튼 클릭")
                        }
                      ]
        )
    }
}
