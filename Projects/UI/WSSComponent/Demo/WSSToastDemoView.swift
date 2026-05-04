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
    var body: some View {
        VStack {
            WSSToastView(type: .changeInfo)
            WSSToastView(type: .deleteBlockUser(nickname: "구리스"))
            WSSToastView(type: .feedEdited)
            WSSToastView(type: .selectionOverLimit(count: 20))
        }
    }
}
