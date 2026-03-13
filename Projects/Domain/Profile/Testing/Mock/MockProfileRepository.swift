//
//  MockProfileRepository.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import ProfileDomain
import BaseDomain

public final class MockProfileRepository: ProfileRepository {

    // MARK: - Call tracking

    public private(set) var syncUserBasicInfoCallCount = 0

    public private(set) var validateNicknameCallCount = 0
    public private(set) var validatedNicknames: [String] = []

    public private(set) var registerProfileCallCount = 0
    public private(set) var registeredProfiles: [ProfileRegistration] = []

    public private(set) var loadAccountInfoDraftCallCount = 0

    public private(set) var saveAccountInfoCallCount = 0
    public private(set) var savedAccountInfos: [AccountInfoDraft] = []

    public private(set) var loadProfileVisibilityCallCount = 0

    public private(set) var updateProfileVisibilityCallCount = 0
    public private(set) var updatedVisibilities: [ProfileVisibility] = []

    public private(set) var fetchUserProfileCallCount = 0
    public private(set) var fetchedUserProfileTargets: [ProfileTarget] = []

    public private(set) var fetchGenrePreferencesCallCount = 0
    public private(set) var fetchedGenrePreferenceTargets: [ProfileTarget] = []

    public private(set) var fetchNovelPreferencesCallCount = 0
    public private(set) var fetchedNovelPreferenceTargets: [ProfileTarget] = []

    public private(set) var fetchProfileCharactersCallCount = 0

    public private(set) var loadInitialProfileCallCount = 0

    public private(set) var updateProfileCallCount = 0
    public private(set) var updatedDrafts: [ProfileDraft] = []

    // MARK: - Results (set by tests)

    public var syncUserBasicInfoResult: Result<Void, RepositoryError> = .success(())
    public var validateNicknameResult: Result<Bool, RepositoryError> = .success(false)
    public var registerProfileResult: Result<Void, RepositoryError> = .success(())

    public var loadAccountInfoDraftResult: Result<AccountInfoDraft, RepositoryError>!
    public var saveAccountInfoResult: Result<Void, RepositoryError> = .success(())

    public var loadProfileVisibilityResult: Result<ProfileVisibility, RepositoryError>!
    public var updateProfileVisibilityResult: Result<Void, RepositoryError> = .success(())

    public var fetchUserProfileResult: Result<Profile, RepositoryError>!
    public var fetchGenrePreferencesResult: Result<[GenrePreference], RepositoryError>!
    public var fetchNovelPreferencesResult: Result<NovelPreference, RepositoryError>!
    public var fetchProfileCharactersResult: Result<[ProfileCharacter], RepositoryError>!

    public var loadInitialProfileResult: Result<ProfileDraft, RepositoryError>!
    public var updateProfileResult: Result<Void, RepositoryError> = .success(())
    
    public init() {}

    // MARK: - ProfileRepository

    public func syncUserBasicInfo() async throws(RepositoryError) {
        syncUserBasicInfoCallCount += 1
        switch syncUserBasicInfoResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    public func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool {
        validateNicknameCallCount += 1
        validatedNicknames.append(nickname)

        switch validateNicknameResult {
        case .success(let value):
            return value
        case .failure(let e):
            throw e
        }
    }

    public func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError) {
        registerProfileCallCount += 1
        registeredProfiles.append(profile)

        switch registerProfileResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    public func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft {
        loadAccountInfoDraftCallCount += 1

        switch loadAccountInfoDraftResult! {
        case .success(let draft):
            return draft
        case .failure(let e):
            throw e
        }
    }

    public func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError) {
        saveAccountInfoCallCount += 1
        savedAccountInfos.append(info)

        switch saveAccountInfoResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    public func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility {
        loadProfileVisibilityCallCount += 1

        switch loadProfileVisibilityResult! {
        case .success(let v):
            return v
        case .failure(let e):
            throw e
        }
    }

    public func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        updateProfileVisibilityCallCount += 1
        updatedVisibilities.append(visibility)

        switch updateProfileVisibilityResult {
        case .success:
            return
        case .failure(let e):
            throw e
        }
    }

    public func fetchUserProfile(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        fetchUserProfileCallCount += 1
        fetchedUserProfileTargets.append(target)
        switch fetchUserProfileResult! {
        case .success(let value): return value
        case .failure(let e): throw e
        }
    }

    public func fetchGenrePreferences(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        fetchGenrePreferencesCallCount += 1
        fetchedGenrePreferenceTargets.append(target)
        switch fetchGenrePreferencesResult! {
        case .success(let value): return value
        case .failure(let e): throw e
        }
    }

    public func fetchNovelPreferences(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        fetchNovelPreferencesCallCount += 1
        fetchedNovelPreferenceTargets.append(target)
        switch fetchNovelPreferencesResult! {
        case .success(let value): return value
        case .failure(let e): throw e
        }
    }

    public func fetchProfileCharacters() async throws(RepositoryError) -> [ProfileCharacter] {
        fetchProfileCharactersCallCount += 1
        switch fetchProfileCharactersResult! {
        case .success(let value): return value
        case .failure(let e): throw e
        }
    }

    public func loadInitialProfile() async throws(RepositoryError) -> ProfileDraft {
        loadInitialProfileCallCount += 1
        switch loadInitialProfileResult! {
        case .success(let value): return value
        case .failure(let e): throw e
        }
    }

    public func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError) {
        updateProfileCallCount += 1
        updatedDrafts.append(profile)

        switch updateProfileResult {
        case .success: return
        case .failure(let e): throw e
        }
    }
}
