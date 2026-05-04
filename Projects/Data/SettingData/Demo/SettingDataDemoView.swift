//
//  SettingDataDemoView.swift
//  SettingDataDemo
//

import SwiftUI

import Networking
import SettingData
import SettingDomain

struct SettingDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var isServiceAgreed: Bool = false
    @State private var isPrivacyAgreed: Bool = false
    @State private var isMarketingAgreed: Bool = false
    @State private var isLoading: Bool = false

    private let termsRepo: TermsAgreementRepository
    private let updateRepo: AppUpdateRepository

    init() {
        let client = NetworkingClient()
        self.termsRepo = SettingDataFactory.makeTermsAgreementRepository(client: client)
        self.updateRepo = SettingDataFactory.makeAppUpdateRepository(client: client)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    appUpdateSection
                    Divider()
                    termsSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Setting Demo")
        }
    }

    // MARK: - Sections

    private var appUpdateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Update").font(.headline).padding(.horizontal)

            demoButton("최소 버전 정책 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                Task { await loadAppUpdatePolicy() }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms Agreement").font(.headline).padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("서비스 이용 동의 (필수)", isOn: $isServiceAgreed)
                Toggle("개인정보 처리방침 (필수)", isOn: $isPrivacyAgreed)
                Toggle("마케팅 정보 수신 동의 (선택)", isOn: $isMarketingAgreed)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                demoButton("약관 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                    Task { await loadTermsDraft() }
                }
                demoButton("약관 저장", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await saveTermsDraft() }
                }
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
            Text(log)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func loadAppUpdatePolicy() async {
        isLoading = true; defer { isLoading = false }
        do {
            let policy = try await updateRepo.loadAppUpdatePolicy()
            log = "최소 버전: \(policy.minimumVersion)\n업데이트 날짜: \(policy.updateDate.map { "\($0)" } ?? "없음")"
        } catch {
            log = "최소 버전 정책 조회 실패\n\(error)"
        }
    }

    private func loadTermsDraft() async {
        isLoading = true; defer { isLoading = false }
        do {
            let draft = try await termsRepo.loadTermsAgreementDraft()
            isServiceAgreed  = draft.isAgreed(.serviceAgreement)
            isPrivacyAgreed  = draft.isAgreed(.privacyPolicy)
            isMarketingAgreed = draft.isAgreed(.marketingConsent)
            log = "약관 조회 성공\n서비스: \(draft.isAgreed(.serviceAgreement))\n개인정보: \(draft.isAgreed(.privacyPolicy))\n마케팅: \(draft.isAgreed(.marketingConsent))"
        } catch {
            log = "약관 조회 실패\n\(error)"
        }
    }

    private func saveTermsDraft() async {
        isLoading = true; defer { isLoading = false }
        var draft = TermsAgreementDraft()
        draft.setAgreed(isServiceAgreed,   for: .serviceAgreement)
        draft.setAgreed(isPrivacyAgreed,   for: .privacyPolicy)
        draft.setAgreed(isMarketingAgreed, for: .marketingConsent)
        do {
            try await termsRepo.save(draft: draft)
            log = "약관 저장 성공\n서비스: \(isServiceAgreed)\n개인정보: \(isPrivacyAgreed)\n마케팅: \(isMarketingAgreed)"
        } catch {
            log = "약관 저장 실패\n\(error)"
        }
    }
}
