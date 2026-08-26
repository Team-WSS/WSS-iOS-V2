//
//  NotificationSettingView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NotificationDomain
import BaseDomain

import DesignSystem
import WSSComponent

struct NotificationSettingView: View {

    @State private var viewModel: NotificationSettingViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationSettingViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear {
                viewModel.handle(.load)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            LoadingView()
        } else if viewModel.state.loadError != nil {
            NetworkErrorView {
                viewModel.handle(.load)
            }
        } else {
            VStack(spacing: 0) {
                settingRow(type: .toggle(isOn: isOnBinding),
                           title: "활동 알림",
                           description: "댓글, 좋아요 알림을 드려요"
                )
                settingRow(type: .navigate(action: {}), // TODO: 완결 알림 상세 화면 이동 연결
                           title: "완결 알림",
                           description: "작품이 완결나면 알림을 드려요"
                )
                settingRow(type: .navigate(action: {}), // TODO: 휴재 복귀 알림 상세 화면 이동 연결
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

// MARK: - Toolbar

private extension NotificationSettingView {
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
            Text("알림 설정")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
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
            )
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
