//
//  DefaultProfileRepository.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import ProfileDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultProfileRepository: ProfileRepository {
    private let service: ProfileService
    private let localStorage: ProfileLocalStorage
    private let logger: DataLogger

    init(
        service: ProfileService,
        localStorage: ProfileLocalStorage,
        logger: DataLogger
    ) {
        self.service = service
        self.localStorage = localStorage
        self.logger = logger
    }

    public func syncUserBasicInfo() async throws(RepositoryError) {
        do {
            let response = try await service.getUserBasicInfo()
            localStorage.userID = response.userId
            localStorage.gender = response.gender
            localStorage.nickname = response.nickname
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "syncUserBasicInfo", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "syncUserBasicInfo", error: error)
            throw .unknown
        }
    }

    public func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool {
        do {
            let response = try await service.validateNickname(nickname)
            return response.isDuplicated
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "validateNickname", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "validateNickname", error: error)
            throw .unknown
        }
    }

    public func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError) {
        do {
            let request = ProfileRegistrationRequest(
                nickname: profile.nickname,
                gender: ProfileMapper.genderRawValue(from: profile.gender),
                birth: profile.birthYear.value,
                genrePreferences: profile.genrePreferences.map { ProfileMapper.novelGenreRawValue(from: $0) }
            )
            try await service.postRegisterProfile(request)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "registerProfile", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "registerProfile", error: error)
            throw .unknown
        }
    }

    public func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft {
        do {
            let response = try await service.getAccountInfo()
            return try ProfileMapper.accountInfoDraft(from: response)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "loadAccountInfoDraft", error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger.logMappingError(action: "loadAccountInfoDraft", error: error)
            throw .invalidData
        } catch {
            logger.logUnknownError(action: "loadAccountInfoDraft", error: error)
            throw .unknown
        }
    }

    public func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError) {
        do {
            let request = AccountInfoRequest(
                gender: ProfileMapper.genderRawValue(from: info.gender),
                birth: info.birth.value
            )
            try await service.putAccountInfo(request)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "saveAccountInfo", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "saveAccountInfo", error: error)
            throw .unknown
        }
    }

    public func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility {
        do {
            let response = try await service.getProfileVisibility()
            return ProfileVisibility(isPublic: response.isPublic)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "loadProfileVisibility", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "loadProfileVisibility", error: error)
            throw .unknown
        }
    }

    public func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        do {
            let request = ProfileVisibilityRequest(isPublic: visibility.isPublic)
            try await service.putProfileVisibility(request)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "updateProfileVisibility", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "updateProfileVisibility", error: error)
            throw .unknown
        }
    }

    public func fetchUserProfile(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getUserProfile(userID: userID)
            return try ProfileMapper.profile(from: response)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "fetchUserProfile", error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger.logMappingError(action: "fetchUserProfile", error: error)
            throw .invalidData
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger.logUnknownError(action: "fetchUserProfile", error: error)
            throw .unknown
        }
    }

    public func fetchGenrePreferences(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getGenrePreferences(userID: userID)
            return ProfileMapper.genrePreferences(from: response.genrePreferences)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "fetchGenrePreferences", error: error)
            throw error.toRepositoryError()
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger.logUnknownError(action: "fetchGenrePreferences", error: error)
            throw .unknown
        }
    }

    public func fetchNovelPreferences(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getNovelPreferences(userID: userID)
            return try ProfileMapper.novelPreference(from: response)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "fetchNovelPreferences", error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger.logMappingError(action: "fetchNovelPreferences", error: error)
            throw .invalidData
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger.logUnknownError(action: "fetchNovelPreferences", error: error)
            throw .unknown
        }
    }

    public func fetchProfileCharacters() async throws(RepositoryError) -> [ProfileCharacter] {
        do {
            let response = try await service.getProfileCharacters()
            return ProfileMapper.profileAvatars(from: response)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "fetchProfileCharacters", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "fetchProfileCharacters", error: error)
            throw .unknown
        }
    }

    public func loadInitialProfile() async throws(RepositoryError) -> ProfileDraft {
        do {
            let nickname = localStorage.nickname ?? ""
            let characterID = localStorage.characterID ?? 0
            let response = try await service.getProfileEditInfo()
            return ProfileMapper.profileDraft(
                from: response,
                nickname: nickname,
                characterID: characterID
            )
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "loadInitialProfile", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "loadInitialProfile", error: error)
            throw .unknown
        }
    }

    public func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError) {
        localStorage.nickname = profile.nickname.text
        localStorage.characterID = profile.characterID

        guard profile.isIntroductionChanged || profile.isGenrePreferencesChanged else { return }

        do {
            let request = UpdateProfileRequest(
                intro: profile.introduction,
                genrePreferences: profile.genrePreferences.map { $0.name }
            )
            try await service.putProfile(request)
        } catch let error as NetworkingError {
            logger.logNetworkError(action: "updateProfile", error: error)
            throw error.toRepositoryError()
        } catch {
            logger.logUnknownError(action: "updateProfile", error: error)
            throw .unknown
        }
    }
}

private extension DefaultProfileRepository {
    func resolveUserID(for target: ProfileTarget) throws(RepositoryError) -> Int {
        switch target {
        case .me:
            guard let userID = localStorage.userID else {
                throw .notFound
            }
            return userID
        case .user(let userID):
            return userID.value
        }
    }
}
