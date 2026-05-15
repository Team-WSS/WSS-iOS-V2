//
//  WSSComponentDemoApp.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

@main
struct WSSComponentDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }
    var body: some Scene {
        WindowGroup {
            WSSAlertDemoView()
        }
    }
}
