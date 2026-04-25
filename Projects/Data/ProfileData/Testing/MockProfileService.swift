//
//  MockProfileService.swift
//  ProfileDataTesting
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
@testable import ProfileData

final class MockProfileService: ProfileService {

    // MARK: - Call tracking

    private(set) var getUserBasicInfoCallCount = 0
    private(set) var validateNicknameCallCount = 0
    private(set) var validatedNicknames: [String] = []
    private(set) var postRegisterProfileCallCount = 0
    private(set) var getAccountInfoCallCount = 0
    private(set) var putAccountInfoCallCount = 0
    private(set) var getProfileVisibilityCallCount = 0
    private(set) var putProfileVisibilityCallCount = 0
    private(set) var getUserProfileCallCount = 0
    private(set) var getUserProfileUserIDs: [Int] = []
    private(set) var getGenrePreferencesCallCount = 0
    private(set) var getGenrePreferencesUserIDs: [Int] = []
    private(set) var getNovelPreferencesCallCount = 0
    private(set) var getNovelPreferencesUserIDs: [Int] = []
    private(set) var getProfileCharactersCallCount = 0
    private(set) var getProfileEditInfoCallCount = 0
    private(set) var putProfileCallCount = 0

    // MARK: - Results

    var getUserBasicInfoResult: Result<UserInfoResponse, Error> = .success(
        UserInfoResponse(userId: 1, gender: "MALE", nickname: "testUser")
    )
    var validateNicknameResult: Result<NicknameValidationResponse, Error> = .success(
        NicknameValidationResponse(isAvailable: true)
    )
    var postRegisterProfileResult: Result<Void, Error> = .success(())
    var getAccountInfoResult: Result<AccountInfoResponse, Error> = .success(
        AccountInfoResponse(email: nil, gender: "MALE", birthYear: 2000)
    )
    var putAccountInfoResult: Result<Void, Error> = .success(())
    var getProfileVisibilityResult: Result<ProfileVisibilityResponse, Error> = .success(
        ProfileVisibilityResponse(isPublic: true)
    )
    var putProfileVisibilityResult: Result<Void, Error> = .success(())
    var getUserProfileResult: Result<UserProfileResponse, Error> = .success(
        UserProfileResponse(nickname: "testUser", introduction: "", characterImage: nil, isPublic: true, genrePreferences: [])
    )
    var getGenrePreferencesResult: Result<GenrePreferenceResponse, Error> = .success(
        GenrePreferenceResponse(genrePreferences: [])
    )
    var getNovelPreferencesResult: Result<NovelPreferenceResponse, Error> = .success(
        NovelPreferenceResponse(attractivePoints: [], keywordPreferences: [])
    )
    var getProfileCharactersResult: Result<ProfileAvatarResponse, Error> = .success(
        ProfileAvatarResponse(avatarProfiles: [])
    )
    var getProfileEditInfoResult: Result<ProfileEditInfoResponse, Error> = .success(
        ProfileEditInfoResponse(introduction: "", genrePreferences: [])
    )
    var putProfileResult: Result<Void, Error> = .success(())

    // MARK: - ProfileService

    func getUserBasicInfo() async throws -> UserInfoResponse {
        getUserBasicInfoCallCount += 1
        return try getUserBasicInfoResult.get()
    }

    func validateNickname(_ nickname: String) async throws -> NicknameValidationResponse {
        validateNicknameCallCount += 1
        validatedNicknames.append(nickname)
        return try validateNicknameResult.get()
    }

    func postRegisterProfile(_ request: ProfileRegistrationRequest) async throws {
        postRegisterProfileCallCount += 1
        try postRegisterProfileResult.get()
    }

    func getAccountInfo() async throws -> AccountInfoResponse {
        getAccountInfoCallCount += 1
        return try getAccountInfoResult.get()
    }

    func putAccountInfo(_ request: AccountInfoRequest) async throws {
        putAccountInfoCallCount += 1
        try putAccountInfoResult.get()
    }

    func getProfileVisibility() async throws -> ProfileVisibilityResponse {
        getProfileVisibilityCallCount += 1
        return try getProfileVisibilityResult.get()
    }

    func putProfileVisibility(_ request: ProfileVisibilityRequest) async throws {
        putProfileVisibilityCallCount += 1
        try putProfileVisibilityResult.get()
    }

    func getUserProfile(userID: Int) async throws -> UserProfileResponse {
        getUserProfileCallCount += 1
        getUserProfileUserIDs.append(userID)
        return try getUserProfileResult.get()
    }

    func getGenrePreferences(userID: Int) async throws -> GenrePreferenceResponse {
        getGenrePreferencesCallCount += 1
        getGenrePreferencesUserIDs.append(userID)
        return try getGenrePreferencesResult.get()
    }

    func getNovelPreferences(userID: Int) async throws -> NovelPreferenceResponse {
        getNovelPreferencesCallCount += 1
        getNovelPreferencesUserIDs.append(userID)
        return try getNovelPreferencesResult.get()
    }

    func getProfileCharacters() async throws -> ProfileAvatarResponse {
        getProfileCharactersCallCount += 1
        return try getProfileCharactersResult.get()
    }

    func getProfileEditInfo() async throws -> ProfileEditInfoResponse {
        getProfileEditInfoCallCount += 1
        return try getProfileEditInfoResult.get()
    }

    func putProfile(_ request: UpdateProfileRequest) async throws {
        putProfileCallCount += 1
        try putProfileResult.get()
    }
}
