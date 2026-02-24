//
//  MockProfileRepository.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  MockProfileRepository.swift
//  ProfileDomainTests
//

import Foundation
import BaseDomain
@testable import ProfileDomain

final class MockProfileRepository: ProfileRepository {

    // MARK: - Call tracking

    private(set) var syncUserBasicInfoCallCount = 0

    private(set) var validateNicknameCallCount = 0
    private(set) var validatedNicknames: [String] = []

    private(set) var registerProfileCallCount = 0
    private(set) var registeredProfiles: [ProfileRegistration] = []

    private(set) var loadAccountInfoDraftCallCount = 0

    private(set) var saveAccountInfoCallCount = 0
    private(set) var savedAccountInfos: [AccountInfoDraft] = []

    private(set) var loadProfileVisibilityCallCount = 0

    private(set) var updateProfileVisibilityCallCount = 0
    private(set) var updatedVisibilities: [ProfileVisibility] = []

    // MARK: - Results (set by tests)

    var syncUserBasicInfoResult: Result<Void, RepositoryError> = .success(())
    var validateNicknameResult: Result<Bool, RepositoryError> = .success(false)
    var registerProfileResult: Result<Void, RepositoryError> = .success(())

    var loadAccountInfoDraftResult: Result<AccountInfoDraft, RepositoryError>!
    var saveAccountInfoResult: Result<Void, RepositoryError> = .success(())

    var loadProfileVisibilityResult: Result<ProfileVisibility, RepositoryError>!
    var updateProfileVisibilityResult: Result<Void, RepositoryError> = .success(())

    // MARK: - ProfileRepository

    func syncUserBasicInfo() async throws(RepositoryError) {
        syncUserBasicInfoCallCount += 1
        switch syncUserBasicInfoResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool {
        validateNicknameCallCount += 1
        validatedNicknames.append(nickname)

        switch validateNicknameResult {
        case .success(let value):
            return value
        case .failure(let e):
            throw e
        }
    }

    func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError) {
        registerProfileCallCount += 1
        registeredProfiles.append(profile)

        switch registerProfileResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft {
        loadAccountInfoDraftCallCount += 1

        switch loadAccountInfoDraftResult! {
        case .success(let draft):
            return draft
        case .failure(let e):
            throw e
        }
    }

    func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError) {
        saveAccountInfoCallCount += 1
        savedAccountInfos.append(info)

        switch saveAccountInfoResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility {
        loadProfileVisibilityCallCount += 1

        switch loadProfileVisibilityResult! {
        case .success(let v):
            return v
        case .failure(let e):
            throw e
        }
    }

    func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        updateProfileVisibilityCallCount += 1
        updatedVisibilities.append(visibility)

        switch updateProfileVisibilityResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }
}