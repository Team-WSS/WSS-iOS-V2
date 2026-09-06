//
//  TermsAgreementView.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/3/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SettingDomain
import DesignSystem
import WSSComponent

/// 온보딩 2단계 — 가입약관 동의 시트. 신규 유저만 인트로 로그인 성공 직후 여기로 들어온다(`NeedOnboarding.value == true`).
/// 필수 항목(서비스 이용약관·개인정보 수집) 전부 동의해야 "다음으로"가 활성화된다 — 필수 온보딩 단계라 스와이프/바깥 탭으로 닫히지 않는다.
struct TermsAgreementView: View {

    @State private var viewModel: TermsAgreementViewModel
    @Environment(\.openURL) private var openURL

    /// 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 로드/저장 등 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void
    /// 저장 성공 시 발화 — 다음 온보딩 단계(닉네임)로 진행할지는 호출자(App)가 결정한다.
    private let onAgreed: () -> Void

    init(
        viewModel: TermsAgreementViewModel,
        onAuthenticationRequired: @escaping () -> Void,
        onAgreed: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onAgreed = onAgreed
    }

    var body: some View {
        content
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                } else if let error = viewModel.state.loadFailed {
                    NetworkErrorView(error: error) { viewModel.handle(.load) }
                }
            }
            // 필수 온보딩 단계 — 동의 없이 스와이프/바깥 탭으로 빠져나갈 수 없다.
            .interactiveDismissDisabled()
            .presentationDetents([.height(670)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.wssWhite)
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldProceed) { _, shouldProceed in
                if shouldProceed { onAgreed() }
            }
            .onChange(of: viewModel.state.requiresAuthentication) { _, needsAuth in
                if needsAuth { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer().frame(height: 64)
            agreementSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }
}

// MARK: - Sections

private extension TermsAgreementView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("웹소소 세계로 들어가는 중...")
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)

            Spacer().frame(height: 8)

            Text("아래 약관 내용에 동의 후 서비스 이용이 가능해요")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var agreementSection: some View {
        VStack(spacing: 0) {
            agreeAllRow

            Spacer().frame(height: 32)

            VStack(spacing: 0) {
                ForEach(TermsType.allCases, id: \.self) { type in
                    agreementRow(type)
                }
            }
        }
    }

    /// "전체 동의" — 필수+선택 전부 토글. 눌림 영역은 행 전체(배경 하이라이트 포함).
    var agreeAllRow: some View {
        Button {
            viewModel.handle(.toggleAgreeAll)
        } label: {
            HStack(spacing: 0) {
                Text("전체 동의")
                    .applyWSSFont(.title2)
                    .foregroundStyle(Color.wssPrimary100)
                    .padding(.leading, 12)

                Spacer()

                checkIcon(isAgreed: viewModel.isAllAgreed)
                    .padding(12)
            }
            .padding(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.wssPrimary20, in: RoundedRectangle(cornerRadius: 14))
    }

    /// 항목 하나 — 라벨(필수 항목은 밑줄+탭하면 상세 약관을 브라우저로 열기)과 개별 체크 토글.
    func agreementRow(_ type: TermsType) -> some View {
        HStack(spacing: 0) {
            agreementLabel(type)

            Spacer()

            Button {
                viewModel.handle(.toggleAgreement(type))
            } label: {
                checkIcon(isAgreed: viewModel.state.draft.isAgreed(type))
                    .padding(12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func agreementLabel(_ type: TermsType) -> some View {
        if let detailURL = type.detailURL {
            Button {
                openURL(detailURL)
            } label: {
                // `.underline()`은 raw Text에 먼저 걸어야 한다(뒤에 걸면 밑줄이 조용히 렌더되지 않는다).
                (Text(type.title).underline() + Text(" (\(type.requirementLabel))"))
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssGray200)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Text("\(type.title) (\(type.requirementLabel))")
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray200)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    var ctaButton: some View {
        WSSCTAButton(
            title: "다음으로",
            isEnabled: viewModel.state.draft.isSubmittable && !viewModel.state.isSaving
        ) {
            viewModel.handle(.proceed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// 체크 아이콘 눌림 피드백 — `CreateFeedConnectNovelRow`(같은 icSelectNovel 아이콘 쌍을 쓰는 정본)와
    /// 동일한 크로스페이드+스케일 스프링으로 통일한다.
    func checkIcon(isAgreed: Bool) -> some View {
        ZStack {
            WSSImage.icSelectNovelDefault.swiftUIImage
                .opacity(isAgreed ? 0 : 1)
                .scaleEffect(isAgreed ? 0.85 : 1)

            WSSImage.icSelectNovelSelected.swiftUIImage
                .opacity(isAgreed ? 1 : 0)
                .scaleEffect(isAgreed ? 1 : 0.6)
        }
        .frame(width: 24, height: 24)
        .animation(.spring(response: 0.32, dampingFraction: 0.6), value: isAgreed)
    }
}

// MARK: - Presentation

private extension TermsAgreementView {
    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.presentedError {
        case .unknown, .none: .unknownError
        }
    }
}

// MARK: - TermsType 표현 매핑
// TermsType은 SettingDomain 소속(BaseDomain 아님)이라 WSSComponent의 DomainPresentation 확장 대상이 아니다
// (UI 레이어는 BaseDomain 외 도메인 타입을 모른다) — 이 화면 로컬 매핑으로 둔다.

private extension TermsType {
    var title: String {
        switch self {
        case .serviceAgreement:  "서비스 이용약관 동의"
        case .privacyPolicy:     "개인정보 수집 및 이용 안내"
        case .marketingConsent:  "마케팅 정보 수신 동의"
        }
    }

    var requirementLabel: String {
        isRequired ? "필수" : "선택"
    }

    /// 상세 약관 URL. 선택 항목(마케팅)은 상세 화면이 없어 탭 대상이 아니다.
    var detailURL: URL? {
        switch self {
        case .serviceAgreement:  AppURL.serviceAgreement
        case .privacyPolicy:     AppURL.privacyPolicy
        case .marketingConsent:  nil
        }
    }
}

// MARK: - Preview

#Preview {
    TermsAgreementView(
        viewModel: TermsAgreementViewModel(
            loadUseCase: PreviewLoadTermsAgreementDraftUseCase(),
            saveUseCase: PreviewSaveTermsAgreementDraftUseCase()
        ),
        onAuthenticationRequired: { print("인증 만료 → 로그인 진입") },
        onAgreed: { print("약관 동의 완료 → 다음 단계") }
    )
}

private struct PreviewLoadTermsAgreementDraftUseCase: LoadTermsAgreementDraftUseCase {
    func execute() async throws(RepositoryError) -> TermsAgreementDraft {
        TermsAgreementDraft()
    }
}

private struct PreviewSaveTermsAgreementDraftUseCase: SaveTermsAgreementDraftUseCase {
    func execute(draft: TermsAgreementDraft) async throws(RepositoryError) {
        print("저장됨!")
    }
}
