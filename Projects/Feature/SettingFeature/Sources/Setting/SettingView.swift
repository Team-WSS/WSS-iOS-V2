//
//  SettingView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import WSSComponent
import Logger
import PushAuthorization

struct SettingView: View {

    @State private var viewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    /// 계정정보 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeAccountInfoView` 조립)은
    /// 호출자(App 조정 계층)가 수행한다.
    private let onAccountInfoTapped: () -> Void
    /// 프로필 공개 설정 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeProfilePublicView` 조립)은
    /// 호출자가 수행한다 — "저장됨" 토스트도 그 전환을 조립하는 쪽(App)이 `onSaveSuccess` 시점에 띄운다
    /// (`MypageRootView`의 프로필 편집 "저장됨" 토스트와 동일 패턴).
    private let onProfilePublicTapped: () -> Void
    /// 알림 설정 진입 콜백 — 이 화면이 시스템 푸시 권한을 먼저 확인한 뒤(denied면 알럿만 띄우고 호출
    /// 안 함) 발화한다. 실제 화면 전환은 호출자(App)가 수행한다.
    private let onNotificationSettingTapped: () -> Void

    init(
        viewModel: SettingViewModel,
        onAccountInfoTapped: @escaping () -> Void = {},
        onProfilePublicTapped: @escaping () -> Void = {},
        onNotificationSettingTapped: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAccountInfoTapped = onAccountInfoTapped
        self.onProfilePublicTapped = onProfilePublicTapped
        self.onNotificationSettingTapped = onNotificationSettingTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SettingMenu.allCases, id: \.self) { menu in
                SettingMenuRow(title: menu.title) {
                    select(menu)
                }
            }

            Spacer()
        }
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.state.shouldNavigateToNotificationSetting) { _, shouldNavigate in
            guard shouldNavigate else { return }
            viewModel.handle(.consumeNotificationSettingNavigation)
            onNotificationSettingTapped()
        }
        .showWSSAlert(
            isPresented: pushAuthorizationAlertBinding,
            type: .setAppNotification,
            buttonActions: [
                { viewModel.handle(.dismissPushAuthorizationAlert) },  // "다음에 하기"
                {
                    viewModel.handle(.dismissPushAuthorizationAlert)
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }  // "설정하러 가기"
            ]
        )
    }

    private func select(_ menu: SettingMenu) {
        switch menu {
        case .accountInfo:
            onAccountInfoTapped()
        case .profileVisibility:
            onProfilePublicTapped()
        case .notification:
            viewModel.handle(.notificationMenuTapped)
        case .officialAccount, .inquiry, .privacyPolicy, .termsOfService:
            if let url = menu.externalURL { openURL(url) }
        }
    }

    private var pushAuthorizationAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isPushAuthorizationAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissPushAuthorizationAlert) } }
        )
    }
}

// MARK: - Menu

extension SettingView {

    enum SettingMenu: CaseIterable {
        case accountInfo
        case profileVisibility
        case notification
        case officialAccount
        case inquiry
        case privacyPolicy
        case termsOfService

        var title: String {
            switch self {
            case .accountInfo:       "계정정보"
            case .profileVisibility: "프로필 공개 설정"
            case .notification:      "알림 설정"
            case .officialAccount:   "웹소소 공식 계정"
            case .inquiry:           "문의하기 & 의견 보내기"
            case .privacyPolicy:     "개인정보 처리방침"
            case .termsOfService:    "서비스 이용약관"
            }
        }

        /// 웹으로 나가는 딥링크. `accountInfo`/`profileVisibility`/`notification`은 앱 내부 화면 전환이라 nil.
        var externalURL: URL? {
            switch self {
            case .officialAccount:   AppURL.instaURL
            case .inquiry:           AppURL.errorReport
            case .privacyPolicy:     AppURL.privacyPolicy
            case .termsOfService:    AppURL.serviceAgreement
            case .accountInfo, .profileVisibility, .notification: nil
            }
        }
    }
}

// MARK: - Toolbar

private extension SettingView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("설정")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingView(
            viewModel: SettingViewModel(pushAuthorizationChecker: PreviewPushAuthorizationChecker())
        )
    }
}

private struct PreviewPushAuthorizationChecker: PushAuthorizationChecker {
    func authorizationStatus() async -> PushAuthorizationStatus { .authorized }
    func requestAuthorization() async -> Bool { true }
}
