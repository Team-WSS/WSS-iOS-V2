//
//  DefaultProfileService.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultProfileService: ProfileService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func getUserBasicInfo() async throws -> UserInfoResponse {
        let endpoint = ProfileEndpoint.getUserInfo
        return try await client.request(endpoint, decodeTo: UserInfoResponse.self)
    }

    func validateNickname(_ nickname: String) async throws -> NicknameValidationResponse {
        let endpoint = ProfileEndpoint.validateNickname(nickname)
        return try await client.request(endpoint, decodeTo: NicknameValidationResponse.self)
    }

    func postRegisterProfile(_ request: ProfileRegistrationRequest) async throws {
        let endpoint = ProfileEndpoint.postRegisterProfile(request)
        _ = try await client.request(endpoint)
    }

    func getAccountInfo() async throws -> AccountInfoResponse {
        let endpoint = ProfileEndpoint.getAccountInfo
        return try await client.request(endpoint, decodeTo: AccountInfoResponse.self)
    }

    func putAccountInfo(_ request: AccountInfoRequest) async throws {
        let endpoint = ProfileEndpoint.putAccountInfo(request)
        _ = try await client.request(endpoint)
    }

    func getProfileVisibility() async throws -> ProfileVisibilityResponse {
        let endpoint = ProfileEndpoint.getProfileVisibility
        return try await client.request(endpoint, decodeTo: ProfileVisibilityResponse.self)
    }

    func putProfileVisibility(_ request: ProfileVisibilityRequest) async throws {
        let endpoint = ProfileEndpoint.patchProfileVisibility(request)
        _ = try await client.request(endpoint)
    }

    func getUserProfile(userID: Int) async throws -> UserProfileResponse {
        let endpoint = ProfileEndpoint.getUserProfile(userID: userID)
        return try await client.request(endpoint, decodeTo: UserProfileResponse.self)
    }

    func getGenrePreferences(userID: Int) async throws -> GenrePreferenceResponse {
        let endpoint = ProfileEndpoint.getGenrePreferences(userID: userID)
        return try await client.request(endpoint, decodeTo: GenrePreferenceResponse.self)
    }

    func getNovelPreferences(userID: Int) async throws -> NovelPreferenceResponse {
        let endpoint = ProfileEndpoint.getNovelPreferences(userID: userID)
        return try await client.request(endpoint, decodeTo: NovelPreferenceResponse.self)
    }

    func getProfileCharacters() async throws -> ProfileAvatarResponse {
        let endpoint = ProfileEndpoint.getProfileAvatars
        return try await client.request(endpoint, decodeTo: ProfileAvatarResponse.self)
    }

    func getProfileEditInfo() async throws -> UserProfileResponse {
        let endpoint = ProfileEndpoint.getProfileInfo
        return try await client.request(endpoint, decodeTo: UserProfileResponse.self)
    }

    func putProfile(_ request: UpdateProfileRequest) async throws {
        let endpoint = ProfileEndpoint.patchProfile(request)
        _ = try await client.request(endpoint)
    }
}
