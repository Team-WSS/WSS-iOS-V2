//
//  WithdrawReasonView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import BaseDomain
import DesignSystem
import WSSComponent

struct WithdrawReasonView: View {

    @FocusState private var isKeyboardFocused: Bool

    @State private var viewModel: WithdrawReasonViewModel
    @Environment(\.dismiss) private var dismiss
    /// 탈퇴 성공으로 화면이 닫힐 때 호출된다. 세션 종료(로그아웃 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면은 성공 신호만 호출자에게 알린다.
    private let onWithdrawSuccess: () -> Void

    init(viewModel: WithdrawReasonViewModel,
         onWithdrawSuccess: @escaping () -> Void = {}) {
        self._viewModel = State(initialValue: viewModel)
        self.onWithdrawSuccess = onWithdrawSuccess
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 51)

                HStack(spacing: 0) {
                    Text("탈퇴사유")
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                    Text("를 알려주세요.")
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                }
                .applyWSSFont(.headline1)
                .padding(.leading, 22)

                Spacer().frame(height: 14)

                VStack(spacing: 2) {
                    ForEach(WithdrawalReasonOption.allCases, id: \.self) { option in
                        withdrawReasonRow(option: option)
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 2)

                otherReasonSection

                Spacer().frame(height: 60)

                Text("탈퇴하기 전에 확인해주세요")
                    .applyWSSFont(.headline1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .padding(.leading, 20)

                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    withdrawConfirmBlock(title: "삭제된 계정 정보는 복구할 수 없어요",
                                         description: "회원님이 평가하고 기록한 서재 정보와 계정 정보는 탈퇴 즉시 삭제되며, 절대 복구할 수 없어요.")
                    withdrawConfirmBlock(title: "게시글 및 댓글은 자동 삭제되지 않아요",
                                         description: "리뷰, 피드 게시글, 댓글은 탈퇴 시 자동으로 삭제되지 않아요.\n탈퇴 전 개별적으로 삭제해 주세요.")
                    withdrawConfirmBlock(title: "처음부터 다시 가입해야 해요",
                                         description: "계정 정보는 탈퇴 즉시 삭제되어 바로 재가입 가능하지만,\n회원가입부터 작품 평가를 다시 해야 해요.")
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                withdrawAgreementSection
                    .padding(.leading, 16)

                Spacer().frame(height: 12.5)

                WSSCTAButton(
                    title: viewModel.state.isSubmitting ? "탈퇴하는 중" : "탈퇴하기",
                    isEnabled: viewModel.isSubmittable && !viewModel.state.isSubmitting,
                    action: { viewModel.handle(.submit) }
                )
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .onTapGesture {
                isKeyboardFocused = false
            }
        }
        .scrollIndicators(.hidden)
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
            guard shouldDismiss else { return }
            onWithdrawSuccess()
            dismiss()
        }
    }

    private func withdrawReasonRow(option: WithdrawalReasonOption) -> some View {
        let isSelected = viewModel.state.draft.option == option

        return Button {
            viewModel.handle(.selectReason(option))
        } label: {
            HStack(spacing: 8) {
                (isSelected ? WSSImage.icSelectNovelSelected.swiftUIImage : WSSImage.icSelectNovelDefault.swiftUIImage)
                    .resizable()
                    .frame(width: 24, height: 24)

                Text(option.title)
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private var otherReasonSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if viewModel.state.draft.customReasonText.isEmpty && !isKeyboardFocused {
                        Text("위 항목 외의 탈퇴 사유를 자유롭게 작성해 주세요.")
                            .applyWSSFont(.body2)
                            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                            .multilineTextAlignment(.leading)
                            .allowsHitTesting(false)
                    }

                    TextField("",
                              text: customReasonTextBinding,
                              axis: .vertical)
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .disabled(!viewModel.state.draft.option.requiresText)
                    .focused($isKeyboardFocused)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 114)
            .background(isKeyboardFocused ? WSSColor.wssWhite.swiftUIColor : WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isKeyboardFocused ? WSSColor.wssGray70.swiftUIColor : Color.clear)
                    .foregroundStyle(Color.clear)
            }
            .onTapGesture {
                if viewModel.state.draft.option != .custom {
                    viewModel.handle(.selectReason(.custom))
                }
                Task { @MainActor in
                    isKeyboardFocused = true
                }
            }

            Spacer().frame(height: 4)

            HStack(spacing: 0) {
                Spacer()
                Text("\(viewModel.state.draft.customReasonText.count)")
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                Text(" / \(WithdrawalReasonDraft.maxCustomReasonLength)")
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            .applyWSSFont(.body4)
        }
        .padding(.horizontal, 20)
    }

    private func withdrawConfirmBlock(title: String,
                                      description: String) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {

                Text(title)
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                Text(description)
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(WSSColor.wssGray50.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var withdrawAgreementSection: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.handle(.togglePolicyAgreed)
            } label: {
                (viewModel.state.draft.policyAgreed ? WSSImage.icSelectNovelSelected.swiftUIImage : WSSImage.icSelectNovelDefault.swiftUIImage)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("위 주의사항을 모두 확인했고, 탈퇴에 동의합니다.")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Toolbar

private extension WithdrawReasonView {
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
            Text("회원탈퇴")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
    }
}

// MARK: - Presentation

private extension WithdrawReasonView {
    var customReasonTextBinding: Binding<String> {
        Binding(
            get: { viewModel.state.draft.customReasonText },
            set: { newValue in
                guard newValue.count <= WithdrawalReasonDraft.maxCustomReasonLength else {
                    return
                }
                viewModel.handle(.setCustomReasonText(newValue))
            }
        )
    }
}

// MARK: - Display

private extension WithdrawalReasonOption {
    var title: String {
        switch self {
        case .notFrequentlyUsed:      "자주 사용하지 않아서"
        case .inconvenientAndBuggy:   "이용이 불편하고 장애가 많아서"
        case .wantToDeleteContent:    "삭제하고 싶은 내용이 있어서"
        case .noDesiredContent:       "원하는 작품이 없어서"
        case .custom:                 "직접입력"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WithdrawReasonView(
            viewModel: WithdrawReasonViewModel(withdrawUseCase: PreviewWithdrawUseCase())
        )
    }
}

private struct PreviewWithdrawUseCase: WithdrawUseCase {
    func execute(draft: WithdrawalReasonDraft) async throws(RepositoryError) {}
}
