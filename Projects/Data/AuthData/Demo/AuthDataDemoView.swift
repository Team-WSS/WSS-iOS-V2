//
//  AuthDataDemoView.swift
//  AuthDataDemo
//

import SwiftUI

import AuthData
import AuthDomain
import BaseData
import BaseDomain
import Keychain
import Logger
import Networking

// MARK: - Log capture

@Observable
private final class LogCapture: Logger {
    var text: String = ""

    func debug(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟦 \(message)" }
    }
    func info(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟩 \(message)" }
    }
    func error(_ message: String) {
        DispatchQueue.main.async { self.text += "\n🟥 \(message)" }
    }
    func clear() {
        DispatchQueue.main.async { self.text = "" }
    }
}

// MARK: - In-memory stores for demo

private final class InMemoryTokenStore: TokenStore {
    private var access: String?
    private var refresh: String?

    func saveAccessToken(_ token: String) throws  { access = token }
    func saveRefreshToken(_ token: String) throws  { refresh = token }
    func accessToken() throws -> String?           { access }
    func refreshToken() throws -> String?          { refresh }
    func clearTokens() throws                      { access = nil; refresh = nil }
}

private final class InMemoryDeviceIdentifierStore: DeviceIdentifierStore {
    private var identifier: String?

    func deviceIdentifier() throws -> String?                  { identifier }
    func saveDeviceIdentifier(_ id: String) throws             { identifier = id }
    func clearDeviceIdentifier() throws                        { identifier = nil }
}

// MARK: - Demo View

struct AuthDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var refreshTokenText: String = ""
    @State private var deviceIDText: String = ""
    @State private var policyAgreed: Bool = false
    @State private var isLoading: Bool = false

    private let repository: AuthRepository
    private let tokenStore: InMemoryTokenStore
    private let deviceIdentifierStore: InMemoryDeviceIdentifierStore
    private let logCapture: LogCapture

    init() {
        let logCapture = LogCapture()
        let ts = InMemoryTokenStore()
        let ds = InMemoryDeviceIdentifierStore()
        try? ts.saveAccessToken(NetworkingConfig.testApiKey)
        let networkLogger = DefaultNetworkLogger(base: logCapture, showBody: true, showHost: false)
        let client = NetworkingClient(logger: networkLogger, tokenStore: ts)
        let dataLogger = DataLogger(moduleName: "Auth", underlying: logCapture)
        self.logCapture = logCapture
        self.tokenStore = ts
        self.deviceIdentifierStore = ds
        self.repository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: ts,
            deviceIdentifierStore: ds,
            logger: dataLogger
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    tokenSetupSection
                    Divider()
                    authSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Auth Demo")
        }
    }

    // MARK: - Sections

    private var tokenSetupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Setup").font(.headline).padding(.horizontal)
            Text("Refresh Token과 Device Identifier를 입력한 후 저장하세요. Access Token은 testApiKey로 자동 설정됩니다.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            TextField("Refresh Token", text: $refreshTokenText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            TextField("Device Identifier", text: $deviceIDText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            demoButton("토큰 저장", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                saveTokens()
            }
            .padding(.horizontal)
        }
    }

    private var authSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Auth").font(.headline).padding(.horizontal)

            demoButton("로그아웃", bg: Color(red: 1.0, green: 0.94, blue: 0.88), fg: .orange) {
                Task { await logout() }
            }
            .padding(.horizontal)

            HStack {
                Toggle("탈퇴 정책 동의", isOn: $policyAgreed)
                    .padding(.horizontal)
            }

            demoButton("회원 탈퇴", bg: Color(red: 1.0, green: 0.92, blue: 0.92), fg: .red) {
                Task { await withdraw() }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private func demoButton(
        _ title: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(fg)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var logSection: some View {
        ScrollView {
            Text(log + logCapture.text)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 300)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func saveTokens() {
        do {
            if !refreshTokenText.isEmpty { try tokenStore.saveRefreshToken(refreshTokenText) }
            if !deviceIDText.isEmpty     { try deviceIdentifierStore.saveDeviceIdentifier(deviceIDText) }
            log = "토큰 저장 완료\nrefresh: \(refreshTokenText.isEmpty ? "(미입력)" : refreshTokenText.prefix(20) + "...")\ndeviceID: \(deviceIDText.isEmpty ? "(미입력)" : deviceIDText)"
        } catch {
            log = "토큰 저장 실패\n\(error)"
        }
    }

    private func logout() async {
        logCapture.clear()
        isLoading = true; defer { isLoading = false }
        do {
            try await repository.logout()
            log = "로그아웃 성공"
        } catch {
            log = "로그아웃 실패\n\(error)"
        }
    }

    private func withdraw() async {
        guard policyAgreed else { log = "탈퇴 정책 동의가 필요합니다."; return }
        logCapture.clear()
        isLoading = true; defer { isLoading = false }
        var draft = WithdrawalReasonDraft()
        draft.setPolicyAgreed(true)
        do {
            try await repository.withdraw(draft: draft)
            log = "회원 탈퇴 성공"
        } catch {
            log = "회원 탈퇴 실패\n\(error)"
        }
    }
}
