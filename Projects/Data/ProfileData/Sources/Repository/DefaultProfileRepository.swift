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
    private let localStorage: AppStorage
    private let logger: DataLogger?

    init(
        service: ProfileService,
        localStorage: AppStorage,
        logger: DataLogger? = nil
    ) {
        self.service = service
        self.localStorage = localStorage
        self.logger = logger
    }

    public func syncUserBasicInfo() async throws(RepositoryError) {
        let action = ProfileAction.syncUserBasicInfo
        
        do {
            let response = try await service.getUserBasicInfo()
            localStorage.set(.userID, response.userId)
            localStorage.set(.gender, response.gender)
            localStorage.set(.nickname, response.nickname)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool {
        let action = ProfileAction.validateNickname
        
        do {
            let response = try await service.validateNickname(nickname)
            return response.isDuplicated
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError) {
        let action = ProfileAction.registerProfile
        
        do {
            let request = ProfileRegistrationRequest(
                nickname: profile.nickname,
                gender: ProfileMapper.genderRawValue(from: profile.gender),
                birth: profile.birthYear.value,
                genrePreferences: profile.genrePreferences.map { ProfileMapper.novelGenreRawValue(from: $0) }
            )
            try await service.postRegisterProfile(request)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft {
        let action = ProfileAction.loadAccountInfoDraft
        
        do {
            let response = try await service.getAccountInfo()
            return try ProfileMapper.accountInfoDraft(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError) {
        let action = ProfileAction.saveAccountInfo
        
        do {
            let request = AccountInfoRequest(
                gender: ProfileMapper.genderRawValue(from: info.gender),
                birth: info.birth.value
            )
            try await service.putAccountInfo(request)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility {
        let action = ProfileAction.loadProfileVisibility
        
        do {
            let response = try await service.getProfileVisibility()
            return ProfileVisibility(isPublic: response.isProfilePublic)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError) {
        let action = ProfileAction.updateProfileVisibility
        
        do {
            let request = ProfileVisibilityRequest(isProfilePublic: visibility.isPublic)
            try await service.putProfileVisibility(request)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchUserProfile(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        let action = ProfileAction.fetchUserProfile
        
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getUserProfile(userID: userID)
            return try ProfileMapper.profile(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchGenrePreferences(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        let action = ProfileAction.fetchGenrePreferences
        
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getGenrePreferences(userID: userID)
            return ProfileMapper.genrePreferences(from: response.genrePreferences)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchNovelPreferences(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        let action = ProfileAction.fetchNovelPreferences
        
        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getNovelPreferences(userID: userID)
            return try ProfileMapper.novelPreference(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch let error as RepositoryError {
            throw error
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func fetchProfileCharacters() async throws(RepositoryError) -> [ProfileCharacter] {
        let action = ProfileAction.fetchProfileCharacters
        
        do {
            let response = try await service.getProfileCharacters()
            return ProfileMapper.profileAvatars(from: response)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadInitialProfile() async throws(RepositoryError) -> ProfileDraft {
        let action = ProfileAction.loadInitialProfile
        
        do {
            let nickname = localStorage.get(.nickname) ?? ""
            let characterID = localStorage.get(.characterID) ?? 0
            let response = try await service.getProfileEditInfo()
            return ProfileMapper.profileDraft(
                from: response,
                nickname: nickname,
                characterID: characterID
            )
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError) {
        let action = ProfileAction.updateProfile
        
        localStorage.set(.nickname, profile.nickname.text)
        localStorage.set(.characterID, profile.characterID)

        guard profile.isIntroductionChanged || profile.isGenrePreferencesChanged else { return }

        do {
            let request = UpdateProfileRequest(
                avatarId: profile.characterID,
                nickname: profile.nickname.text,
                intro: profile.introduction,
                genrePreferences: profile.genrePreferences.map { $0.name }
            )
            try await service.putProfile(request)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}

private extension DefaultProfileRepository {
    func resolveUserID(for target: ProfileTarget) throws(RepositoryError) -> Int {
        switch target {
        case .me:
            guard let userID = localStorage.get(.userID) else {
                throw .notFound
            }
            return userID
        case .user(let userID):
            return userID.value
        }
    }
}
