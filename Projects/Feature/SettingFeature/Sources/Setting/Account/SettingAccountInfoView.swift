//
//  SettingAccountInfoView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import AuthDomain
import DesignSystem
import WSSComponent
import Logger

struct SettingAccountInfoView: View {

    @State private var viewModel: SettingAccountInfoViewModel
    @Environment(\.dismiss) private var dismiss

    /// 로그아웃 성공 시 호출된다. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면은 성공 신호만 호출자에게 전달한다.
    private let onLogoutSuccess: () -> Void
    /// 성별/나이 변경 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeChangeGenderOrAgeView` 조립)
    /// 은 호출자(App)가 수행한다 — "저장됨" 토스트도 그 전환을 조립하는 쪽이 `onSaveSuccess` 시점에 띄운다.
    private let onChangeGenderOrAgeTapped: () -> Void
    /// 차단유저 목록 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeBlockUserListView` 조립)은
    /// 호출자가 수행한다.
    private let onBlockUserListTapped: () -> Void
    /// 회원탈퇴 진입 콜백. 실제 화면 전환(`SettingFeatureFactory.makeWithdrawFlowView` 조립)은
    /// 호출자가 수행한다 — 확인→사유 2단계는 그 화면 안에서 여전히 로컬로 진행된다(`WithdrawFlowView` 참고).
    private let onWithdrawTapped: () -> Void

    init(
        viewModel: SettingAccountInfoViewModel,
        onLogoutSuccess: @escaping () -> Void = {},
        onChangeGenderOrAgeTapped: @escaping () -> Void = {},
        onBlockUserListTapped: @escaping () -> Void = {},
        onWithdrawTapped: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onLogoutSuccess = onLogoutSuccess
        self.onChangeGenderOrAgeTapped = onChangeGenderOrAgeTapped
        self.onBlockUserListTapped = onBlockUserListTapped
        self.onWithdrawTapped = onWithdrawTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SettingMenu.allCases, id: \.self) { menu in
                SettingMenuRow(
                    title: menu.title,
                    bottomText: menu == .email ? viewModel.state.email : nil,
                    action: menu.isSelectable ? { select(menu) } : nil
                )
            }

            Spacer()
        }
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.handle(.load)
        }
        .showWSSAlert(
            isPresented: logoutAlertBinding,
                      type: .logout,
                      buttonActions: [
                        { viewModel.handle(.cancelLogout) },
                        { viewModel.handle(.confirmLogout) }
                      ]
        )
        .showWSSToast(isPresented: logoutErrorToastBinding, type: .unknownError)
        .onChange(of: viewModel.state.logoutSucceeded) { _, logoutSucceeded in
            guard logoutSucceeded else { return }
            onLogoutSuccess()
        }
    }

    private func select(_ menu: SettingMenu) {
        switch menu {
        case .changeGenderOrAge:
            onChangeGenderOrAgeTapped()
        case .blockUserList:
            onBlockUserListTapped()
        case .withdraw:
            onWithdrawTapped()
        case .logout:
            viewModel.handle(.presentLogoutAlert)
        case .email:
            break
        }
    }
}

// MARK: - Presentation

private extension SettingAccountInfoView {
    var logoutAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isLogoutAlertPresented },
            set: { if !$0 { viewModel.handle(.cancelLogout) } }
        )
    }

    var logoutErrorToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }
}

// MARK: - Menu

extension SettingAccountInfoView {

    enum SettingMenu: CaseIterable {
        case changeGenderOrAge
        case email
        case blockUserList
        case logout
        case withdraw

        var title: String {
            switch self {
            case .changeGenderOrAge:    "성별/나이 변경"
            case .email:                "이메일"
            case .blockUserList:        "차단유저 목록"
            case .logout:               "로그아웃"
            case .withdraw:             "회원탈퇴"
            }
        }

        var isSelectable: Bool {
            switch self {
            case .email:    false
            default:        true
            }
        }
    }
}

// MARK: - Toolbar

private extension SettingAccountInfoView {
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
            Text("계정정보")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
    }
}

#Preview {
    NavigationStack {
        SettingAccountInfoView(
            viewModel: SettingAccountInfoViewModel(
                loadAccountInfoDraftUseCase: PreviewLoadAccountInfoDraftUseCase(),
                logoutUseCase: PreviewLogoutUseCase()
            )
        )
    }
}

private struct PreviewLogoutUseCase: LogoutUseCase {
    func execute() async throws(RepositoryError) {}
}

private struct PreviewLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: "wss@websoso.kr", gender: .female, birth: try! BirthYear(2001))
    }
}
