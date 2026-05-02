//
//  ProfileService.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol ProfileService {
    func getUserBasicInfo() async throws -> UserInfoResponse
    func validateNickname(_ nickname: String) async throws -> NicknameValidationResponse
    func postRegisterProfile(_ request: ProfileRegistrationRequest) async throws
    func getAccountInfo() async throws -> AccountInfoResponse
    func putAccountInfo(_ request: AccountInfoRequest) async throws
    func getProfileVisibility() async throws -> ProfileVisibilityResponse
    func putProfileVisibility(_ request: ProfileVisibilityRequest) async throws
    func getUserProfile(userID: Int) async throws -> UserProfileResponse
    func getGenrePreferences(userID: Int) async throws -> GenrePreferenceResponse
    func getNovelPreferences(userID: Int) async throws -> NovelPreferenceResponse
    func getProfileCharacters() async throws -> ProfileAvatarResponse
    func getProfileEditInfo() async throws -> UserProfileResponse
    func putProfile(_ request: UpdateProfileRequest) async throws
}
