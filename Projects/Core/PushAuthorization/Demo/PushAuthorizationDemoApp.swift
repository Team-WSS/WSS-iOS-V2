//
//  PushAuthorizationDemoApp.swift
//  PushAuthorizationDemo
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import PushAuthorization

@main
struct PushAuthorizationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var status: PushAuthorizationStatus?
    @State private var lastRequestResult: Bool?

    private let checker: PushAuthorizationChecker = DefaultPushAuthorizationChecker()

    var body: some View {
        NavigationStack {
            Form {
                Section("현재 상태") {
                    Text(statusText)
                        .foregroundStyle(.secondary)
                }

                Section("Actions") {
                    Button("상태 조회") { Task { await refreshStatus() } }
                    Button("권한 요청") { Task { await requestAuthorization() } }
                }

                if let lastRequestResult {
                    Section("요청 결과") {
                        Text(lastRequestResult ? "✅ 허용됨" : "❌ 거부됨/실패")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("🔔 PushAuthorization Demo")
            .task { await refreshStatus() }
        }
    }

    private var statusText: String {
        switch status {
        case .authorized:    "authorized (알림 받을 수 있음)"
        case .denied:        "denied (기기 설정에서 거부됨)"
        case .notDetermined: "notDetermined (아직 안 물어봄)"
        case nil:             "조회 전"
        }
    }

    private func refreshStatus() async {
        status = await checker.authorizationStatus()
    }

    private func requestAuthorization() async {
        lastRequestResult = await checker.requestAuthorization()
        await refreshStatus()
    }
}
