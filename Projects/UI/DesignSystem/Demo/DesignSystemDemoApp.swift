//
//  DesignSystemDemoApp.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

@main
struct DesignSystemDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }
    var body: some Scene {
        WindowGroup {
            WSSFontDemoView()
        }
    }
}
