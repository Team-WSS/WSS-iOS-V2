//
//  NotificationSettingView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain

import DesignSystem
import WSSComponent

struct NotificationSettingView: View {

    @State private var viewModel: NotificationSettingViewModel
    @Environment(\.dismiss) private var dismiss

    /// 화면 전환 의도 콜백(#253) — 계약은 `NotificationSettingRoute`(Navigation/)가 정본.
    private let onRoute: (NotificationSettingRoute) -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 로드·토글이 401로 막히면 발화(Feature 공통 계약).
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: NotificationSettingViewModel,
        onRoute: @escaping (NotificationSettingRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onRoute = onRoute
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "알림 설정") { dismiss() }

            content
        }
            .wssCustomNavigationBar()
            .onAppear {
                viewModel.handle(.load)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            LoadingView()
        } else if let error = viewModel.state.loadError {
            NetworkErrorView(error: error) {
                viewModel.handle(.load)
            }
        } else {
            VStack(spacing: 0) {
                settingRow(type: .toggle(isOn: isOnBinding),
                           title: "활동 알림",
                           description: "댓글, 좋아요 알림을 드려요"
                )
                settingRow(type: .navigate(action: { onRoute(.completionNotificationList) }),
                           title: "완결 알림",
                           description: "작품이 완결나면 알림을 드려요"
                )
                settingRow(type: .navigate(action: { onRoute(.hiatusReturnNotificationList) }),
                           title: "휴재 복귀 알림",
                           description: "새로운 회차가 생기면 알림을 드려요"
                )

                Spacer()
            }
        }
    }

    enum RowType {
        case toggle(isOn: Binding<Bool>)
        case navigate(action: () -> Void)
    }

    private func settingRow(type: RowType,
                            title: String,
                            description: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                    Text(description)
                        .applyWSSFont(.body3)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                }

                Spacer()

                switch type {
                case .toggle(let isOn):
                    WSSToggleButton(isOn: isOn)
                case .navigate:
                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12.5)
            .contentShape(Rectangle())
            .onTapGesture {
                if case .navigate(let action) = type {
                    action()
                }
            }

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
        }
    }
}


// MARK: - Presentation

private extension NotificationSettingView {
    var isOnBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isNotificationOn },
            set: { viewModel.handle(.toggleNotificationOn($0)) }
        )
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.toastError != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.toastError {
        case .unknown, .none: .unknownError
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingView(
            viewModel: NotificationSettingViewModel(
                loadPushPreferenceUseCase: PreviewLoadPushPreferenceUseCase(),
                updatePushPreferenceUseCase: PreviewUpdatePushPreferenceUseCase()
            ),
            onRoute: { print("화면 전환 요청: \($0)") }
        )
    }
}

private struct PreviewLoadPushPreferenceUseCase: LoadPushPreferenceUseCase {
    func execute() async throws(RepositoryError) -> PushPreference {
        PushPreference(isEnabled: true)
    }
}

private struct PreviewUpdatePushPreferenceUseCase: UpdatePushPreferenceUseCase {
    func execute(pushPreference: PushPreference) async throws(RepositoryError) {}
}
