//
//  Demo.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/25/25.
//

import SwiftUI
import DesignSystem
import WSSComponent

@main
struct WSSComponentDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NetworkErrorView(action: {})
    }
}
