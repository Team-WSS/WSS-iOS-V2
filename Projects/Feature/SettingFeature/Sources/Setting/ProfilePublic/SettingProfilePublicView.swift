//
//  SettingProfilePublicView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import DesignSystem
import WSSComponent

struct SettingProfilePublicView: View {

    @State private var viewModel: SettingProfilePublicViewModel
    @Environment(\.dismiss) private var dismiss
    /// 저장 성공으로 화면이 닫힐 때 호출된다(변경 결과가 공개/비공개인지 함께 전달). 토스트는 이 화면이
    /// 사라진 뒤 이전 화면에서 보여야 자연스러워 이 화면 스스로 띄우지 않고, 호출자에게 결과만 알린다.
    private let onSaveSuccess: (Bool) -> Void

    init(
        viewModel: SettingProfilePublicViewModel,
         onSaveSuccess: @escaping (Bool) -> Void = { _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
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
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                guard shouldDismiss else { return }
                onSaveSuccess(viewModel.state.isPublic)
                dismiss()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            LoadingView()
        } else if viewModel.state.presentedError != nil {
            NetworkErrorView {
                viewModel.handle(.load)
            }
        } else {
            settingRowSection
        }
    }

    private var settingRowSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("비공개")
                    .applyWSSFont(.body1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                Spacer()

                WSSToggleButton(isOn: isPublicBinding)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10.5)

            Spacer()
        }
    }
}

// MARK: - Toolbar

private extension SettingProfilePublicView {
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
            Text("프로필 공개 설정")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.handle(.save)
            } label: {
                if viewModel.state.isSaving {
                    ProgressView()
                } else {
                    Text("완료")
                        .applyWSSFont(.title2)
                        .foregroundStyle(
                            viewModel.hasChanges
                                ? WSSColor.wssPrimary100.swiftUIColor
                                : WSSColor.wssGray100.swiftUIColor
                        )
                }
            }
            .disabled(viewModel.state.isSaving || !viewModel.hasChanges)
        }
    }
}

// MARK: - Presentation

private extension SettingProfilePublicView {
    /// 토글 라벨이 "비공개"로 고정돼 있어, 스위치는 "비공개 여부"를 보여준다 — `state.isPublic`과는 반대 방향.
    var isPublicBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.state.isPublic },
            set: { viewModel.handle(.togglePublic(!$0)) }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingProfilePublicView(
            viewModel: SettingProfilePublicViewModel(
                loadProfileVisibilityUseCase: PreviewLoadProfileVisibilityUseCase(),
                updateProfileVisibilityUseCase: PreviewUpdateProfileVisibilityUseCase()
            )
        )
    }
}

private struct PreviewLoadProfileVisibilityUseCase: LoadProfileVisibilityUseCase {
    func execute() async throws(RepositoryError) -> ProfileVisibility {
        ProfileVisibility(isPublic: true)
    }
}

private struct PreviewUpdateProfileVisibilityUseCase: UpdateProfileVisibilityUseCase {
    func execute(_ visibility: ProfileVisibility) async throws(RepositoryError) {}
}
