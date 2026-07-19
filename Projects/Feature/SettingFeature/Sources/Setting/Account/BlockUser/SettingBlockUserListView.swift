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
        content
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear {
                viewModel.handle(.load)
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.presentedError != nil {
                NetworkErrorView {
                    viewModel.handle(.load)
                }
            } else if viewModel.state.blockedUsers.isEmpty {
                noBlockUserSection
            } else {
                blockUserListSection
            }
        }
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

// MARK: - Toolbar

private extension SettingBlockUserListView {
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
            Text("차단유저 목록")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
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
