//
//  Demo.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/25/25.
//

import SwiftUI
import WSSComponent

@main
struct WSSComponentDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NetworkErrorView(onRetry: {})
    }
}
