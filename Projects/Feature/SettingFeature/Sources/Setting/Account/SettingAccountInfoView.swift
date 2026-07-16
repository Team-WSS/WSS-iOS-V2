//
//  SettingAccountInfoView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SettingDomain
import ProfileDomain
import SocialDomain
import AuthDomain
import DesignSystem
import WSSComponent
import Logger

struct SettingAccountInfoView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isChangeGenderOrAgePresented = false
    @State private var isBlockUserListPresented = false
    @State private var isWithdrawConfirmPresented = false
    @State private var isWithdrawReasonPresented = false
    /// 성별/나이 변경 화면이 저장 성공으로 dismiss된 뒤, 돌아온 이 화면에서 띄운다.
    @State private var isChangeSavedToastPresented = false

    private let logger: Logger?
    /// 탈퇴 성공 시 호출된다. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
    /// 이 화면들을 모두 지나 호출자에게 성공 신호만 전달한다.
    private let onWithdrawSuccess: () -> Void

    // ProfileDomain
    private let loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase
    private let saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase

    // SocialDomain
    private let loadBlockedUsersUseCase: LoadBlockedUsersUseCase
    private let unblockUserUseCase: UnblockUserUseCase

    // AuthDomain
    private let withdrawUseCase: WithdrawUseCase

    init(
        loadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase,
        saveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase,
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {}
    ) {
        self.loadLocalGenderAndBirthUseCase = loadLocalGenderAndBirthUseCase
        self.saveAccountInfoDraftUseCase = saveAccountInfoDraftUseCase
        self.loadBlockedUsersUseCase = loadBlockedUsersUseCase
        self.unblockUserUseCase = unblockUserUseCase
        self.withdrawUseCase = withdrawUseCase
        self.logger = logger
        self.onWithdrawSuccess = onWithdrawSuccess
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SettingMenu.allCases, id: \.self) { menu in
                SettingMenuRow(
                    title: menu.title,
                    action: menu.isSelectable ? { select(menu) } : nil
                )
            }

            Spacer()
        }
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isChangeGenderOrAgePresented) {
            SettingChangeGenderOrAgeView(
                viewModel: SettingChangeGenderOrAgeViewModel(
                    loadLocalGenderAndBirthUseCase: loadLocalGenderAndBirthUseCase,
                    saveAccountInfoDraftUseCase: saveAccountInfoDraftUseCase,
                    logger: logger
                ),
                onSaveSuccess: { isChangeSavedToastPresented = true }
            )
        }
        .navigationDestination(isPresented: $isBlockUserListPresented) {
            SettingBlockUserListView(
                viewModel: SettingBlockUserListViewModel(
                    loadBlockedUsersUseCase: loadBlockedUsersUseCase,
                    unblockUserUseCase: unblockUserUseCase,
                    logger: logger
                )
            )
        }
        .navigationDestination(isPresented: $isWithdrawConfirmPresented) {
            WithdrawConfirmView(onConfirm: { isWithdrawReasonPresented = true })
        }
        .navigationDestination(isPresented: $isWithdrawReasonPresented) {
            WithdrawReasonView(
                viewModel: WithdrawReasonViewModel(
                    withdrawUseCase: withdrawUseCase,
                    logger: logger
                ),
                onWithdrawSuccess: onWithdrawSuccess
            )
        }
        .showWSSToast(isPresented: $isChangeSavedToastPresented, type: .changeInfo)
    }

    private func select(_ menu: SettingMenu) {
        switch menu {
        case .changeGenderOrAge:
            isChangeGenderOrAgePresented = true
        case .blockUserList:
            isBlockUserListPresented = true
        case .withdraw:
            isWithdrawConfirmPresented = true
        case .logout:
            break // TODO: 하위 화면 이동 연결
        case .email:
            break
        }
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
            loadLocalGenderAndBirthUseCase: PreviewLoadLocalGenderAndBirthUseCase(),
            saveAccountInfoDraftUseCase: PreviewSaveAccountInfoDraftUseCase(),
            loadBlockedUsersUseCase: PreviewLoadBlockedUsersUseCase(),
            unblockUserUseCase: PreviewUnblockUserUseCase(),
            withdrawUseCase: PreviewWithdrawUseCase()
        )
    }
}

private struct PreviewLoadLocalGenderAndBirthUseCase: LoadLocalGenderAndBirthUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft {
        AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(2001))
    }
}

private struct PreviewSaveAccountInfoDraftUseCase: SaveAccountInfoDraftUseCase {
    func execute(_ info: AccountInfoDraft) async throws(RepositoryError) {}
}

private struct PreviewLoadBlockedUsersUseCase: LoadBlockedUsersUseCase {
    func execute() async throws(RepositoryError) -> [BlockedUser] {
        [BlockedUser(blockID: BlockID(1), userID: UserID(1), nickname: "구리스", profileImageURL: nil)]
    }
}

private struct PreviewUnblockUserUseCase: UnblockUserUseCase {
    func execute(id: BlockID) async throws(RepositoryError) {}
}

private struct PreviewWithdrawUseCase: WithdrawUseCase {
    func execute(draft: WithdrawalReasonDraft) async throws(RepositoryError) {}
}
