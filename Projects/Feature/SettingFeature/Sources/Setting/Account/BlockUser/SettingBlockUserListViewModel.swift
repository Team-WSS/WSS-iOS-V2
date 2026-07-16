//
//  SettingBlockUserListViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import SocialDomain
import Logger

@MainActor
@Observable
final class SettingBlockUserListViewModel {

    // MARK: - State

    struct State {
        var blockedUsers: [BlockedUser] = []
        var isLoading = false
        /// 차단 해제 중인 행(row)들. 중복 탭 방지 + 개별 스피너 표시에 쓴다.
        var unblockingBlockIDs: Set<BlockID> = []
        /// 방금 차단 해제에 성공한 유저. 성공 토스트("OO님을 차단 해제했어요") 표시용.
        var unblockedUser: BlockedUser?
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: SettingError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum SettingError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case unblock(BlockedUser)
        case dismissToast
    }

    // MARK: - Output

    private(set) var state: State = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false

    // MARK: - Dependency

    private let logger: Logger?

    // SocialDomain
    private let loadBlockedUsersUseCase: LoadBlockedUsersUseCase
    private let unblockUserUseCase: UnblockUserUseCase

    // MARK: - Init

    init(
        loadBlockedUsersUseCase: LoadBlockedUsersUseCase,
        unblockUserUseCase: UnblockUserUseCase,
        logger: Logger? = nil
    ) {
        self.loadBlockedUsersUseCase = loadBlockedUsersUseCase
        self.unblockUserUseCase = unblockUserUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .unblock(let user):
            unblock(user)
        case .dismissToast:
            state.presentedError = nil
            state.unblockedUser = nil
        }
    }
}

// MARK: - Action Handling

private extension SettingBlockUserListViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        Task { await loadBlockedUsers() }
    }

    func unblock(_ user: BlockedUser) {
        guard !state.unblockingBlockIDs.contains(user.blockID) else { return }
        state.unblockingBlockIDs.insert(user.blockID)
        Task { await unblockUser(user) }
    }
}

// MARK: - UseCase Handling

private extension SettingBlockUserListViewModel {
    func loadBlockedUsers() async {
        defer { state.isLoading = false }
        do {
            state.blockedUsers = try await loadBlockedUsersUseCase.execute()
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }

    func unblockUser(_ user: BlockedUser) async {
        defer { state.unblockingBlockIDs.remove(user.blockID) }

        do {
            try await unblockUserUseCase.execute(id: user.blockID)
            state.blockedUsers.removeAll { $0.blockID == user.blockID }
            state.unblockedUser = user
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SettingBlockUserListViewModel {
    func presentError(_ error: Error) {
        logger?.error("SettingBlockUserList 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = .unknown
    }
}
