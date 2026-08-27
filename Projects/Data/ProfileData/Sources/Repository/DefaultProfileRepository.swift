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

struct DefaultProfileRepository: ProfileRepository {
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
            logger?.logSuccess(action: action.name)
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
            let query = ValidateNicknameQuery(nickname: nickname)
            let response = try await service.validateNickname(query)
            logger?.logSuccess(action: action.name)
            return response.isValid
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
            logger?.logSuccess(action: action.name)
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
            let result = try ProfileMapper.accountInfoDraft(from: response)
            logger?.logSuccess(action: action.name)
            return result
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
            localStorage.set(.gender, ProfileMapper.localGenderRawValue(from: info.gender))
            localStorage.set(.birthYear, info.birth.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadLocalGenderAndBirth() async throws(RepositoryError) -> AccountInfoDraft {
        let action = ProfileAction.loadLocalGenderAndBirth

        if let genderRaw = localStorage.get(.gender),
           let birthValue = localStorage.get(.birthYear) {
            do {
                let result = try ProfileMapper.localGenderAndBirth(genderRaw: genderRaw, birthValue: birthValue)
                logger?.logSuccess(action: action.name)
                return result
            } catch let error as MappingError {
                logger?.logMappingError(action: action.name, error: error)
                throw .invalidData
            } catch {
                logger?.logUnknownError(action: action.name, error: error)
                throw .invalidData
            }
        }

        // syncUserBasicInfo()는 birthYear를 로컬에 쓰지 않아, "성별/나이 변경" 화면을 한 번도
        // 저장한 적 없는 사용자는 로컬에 값이 없다 — 이 경우 서버(계정정보 API)에서 읽어와
        // 다음부터는 로컬로도 읽을 수 있도록 캐시한다.
        do {
            let response = try await service.getAccountInfo()
            let result = try ProfileMapper.accountInfoDraft(from: response)
            localStorage.set(.gender, ProfileMapper.localGenderRawValue(from: result.gender))
            localStorage.set(.birthYear, result.birth.value)
            logger?.logSuccess(action: action.name)
            return result
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

    public func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility {
        let action = ProfileAction.loadProfileVisibility
        
        do {
            let response = try await service.getProfileVisibility()
            let result = ProfileVisibility(isPublic: response.isProfilePublic)
            logger?.logSuccess(action: action.name)
            return result
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
            logger?.logSuccess(action: action.name)
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
            let result = try ProfileMapper.profile(from: response)
            logger?.logSuccess(action: action.name)
            return result
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
            let result = try ProfileMapper.genrePreferences(from: response.genrePreferences)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            // 상대가 프로필을 비공개로 설정한 경우 — HTTP 상태 코드보다 서버 비즈니스 코드로 식별한다.
            if case .responseFailure(_, let body) = error, body?.code == "USER-015" {
                throw .privateProfile
            }
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

    public func fetchNovelPreferences(_ target: ProfileTarget, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelPreference {
        let action = ProfileAction.fetchNovelPreferences

        do {
            let userID = try resolveUserID(for: target)
            let response = try await service.getNovelPreferences(userID: userID)
            let lookup = Dictionary(
                cachedKeywords.map { ($0.name, $0.id) },
                uniquingKeysWith: { first, _ in first }
            )
            let result = try ProfileMapper.novelPreference(from: response, keywordLookup: lookup)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            // 상대가 프로필을 비공개로 설정한 경우 — HTTP 상태 코드보다 서버 비즈니스 코드로 식별한다.
            if case .responseFailure(_, let body) = error, body?.code == "USER-015" {
                throw .privateProfile
            }
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
            let result = ProfileMapper.profileAvatars(from: response)
            logger?.logSuccess(action: action.name)
            return result
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
            let characterID = localStorage.get(.characterID) ?? 0
            let response = try await service.getProfileEditInfo()
            let result = try ProfileMapper.profileDraft(
                from: response,
                characterID: characterID
            )
            logger?.logSuccess(action: action.name)
            return result
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

    public func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError) {
        let action = ProfileAction.updateProfile

        guard profile.isNicknameChanged
                || profile.isIntroductionChanged
                || profile.isCharacterChanged
                || profile.isGenrePreferencesChanged
        else { return }

        do {
            // PATCH라 바뀐 필드만 값을 보내고 나머지는 nil로 둔다(서버가 nil을 "변경 없음"으로 해석).
            // genrePreferences만 예외 — 서버가 null을 허용하지 않아, 바뀌지 않았어도 현재 전체 목록을 그대로 보낸다.
            let request = UpdateProfileRequest(
                avatarId: profile.isCharacterChanged ? profile.characterID : nil,
                nickname: profile.isNicknameChanged ? profile.nickname.text : nil,
                intro: profile.isIntroductionChanged ? profile.introduction : nil,
                genrePreferences: profile.genrePreferences.map { ProfileMapper.novelGenreRawValue(from: $0.genre) }
            )
            try await service.putProfile(request)
            // 로컬 캐시(닉네임/캐릭터ID)는 서버 반영이 확정된 뒤에만 갱신한다 — PATCH보다 먼저 쓰면
            // 요청이 실패해도 롤백되지 않아 로컬과 서버가 어긋난다(MyPageEditView가 실패한 변경을
            // "저장된 값"처럼 계속 보여주던 버그의 원인).
            localStorage.set(.nickname, profile.nickname.text)
            localStorage.set(.characterID, profile.characterID)
            logger?.logSuccess(action: action.name)
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
