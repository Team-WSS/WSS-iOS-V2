//
//  WSSToastDemoView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import WSSComponent

struct WSSToastDemoView: View {
    @State private var showToast = false
    
    var body: some View {
        VStack {
            WSSToastView(type: .blockUser(nickname: "구리스"))
            WSSToastView(type: .novelAlreadyConnected)
            WSSToastView(type: .limitAddImage(limitCount: 5))
            
            Button("changeInfo 토스트 버튼") {
                showToast = true
            }
        }
        .showWSSToast(isPresented: $showToast,
                      type: .changeInfo)
    }
}
