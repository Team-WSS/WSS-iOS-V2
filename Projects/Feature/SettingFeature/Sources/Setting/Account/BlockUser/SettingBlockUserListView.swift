//
//  SettingBlockUserListView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SocialDomain
import DesignSystem
import WSSComponent

struct SettingBlockUserListView: View {

    @State private var viewModel: SettingBlockUserListViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingBlockUserListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "차단유저 목록") { dismiss() }

            content
        }
            .wssCustomNavigationBar()
            .onAppear {
                viewModel.handle(.load)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.loadError != nil {
                NetworkErrorView {
                    viewModel.handle(.load)
                }
            } else if viewModel.state.blockedUsers.isEmpty {
                noBlockUserSection
            } else {
                blockUserListSection
            }
        }
        // 네비바 아래 남은 세로 공간을 채운다 — 빈 상태(이미지+문구)가 네비바에 붙지 않고 중앙에 오도록.
        // (예전엔 content가 body 루트라 화면을 꽉 채웠는데, 네비바와 한 VStack에 묶이며 채움이 사라졌다.)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var blockUserListSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.state.blockedUsers, id: \.blockID) { user in
                    BlockUserRow(
                        user: user,
                        isUnblocking: viewModel.state.unblockingBlockIDs.contains(user.blockID),
                        onUnblock: { viewModel.handle(.unblock(user)) }
                    )
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var noBlockUserSection: some View {
        VStack(spacing: 20) {
            WSSImage.imgEmptyCatEyes.swiftUIImage

            Text("차단한 유저가 없어요")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
    }
}

// MARK: - Presentation

private extension SettingBlockUserListView {
    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.toastError != nil || viewModel.state.unblockedUser != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        if let unblockedUser = viewModel.state.unblockedUser {
            return .deleteBlockUser(nickname: unblockedUser.nickname)
        }
        switch viewModel.state.toastError {
        case .unknown, .none: return .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingBlockUserListView(
            viewModel: SettingBlockUserListViewModel(
                loadBlockedUsersUseCase: PreviewLoadBlockedUsersUseCase(),
                unblockUserUseCase: PreviewUnblockUserUseCase()
            )
        )
    }
}

private struct PreviewLoadBlockedUsersUseCase: LoadBlockedUsersUseCase {
    func execute() async throws(RepositoryError) -> [BlockedUser] {
        [
            BlockedUser(blockID: BlockID(1), userID: UserID(1), nickname: "구리스", profileImageURL: nil),
            BlockedUser(blockID: BlockID(2), userID: UserID(2), nickname: "웹소소", profileImageURL: nil)
        ]
    }
}

private struct PreviewUnblockUserUseCase: UnblockUserUseCase {
    func execute(id: BlockID) async throws(RepositoryError) {}
}
