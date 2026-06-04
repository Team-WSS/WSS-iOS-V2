//
//  ProfileRepository.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol ProfileRepository {
    
    /// 받아온 성별, userID, 닉네임을 userDefaults에 저장
    func syncUserBasicInfo() async throws(RepositoryError)
    func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool
    func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError)
    
    func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft
    func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError)
    
    func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility
    func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError)
    
    /// target에 따라 로직을 분리한다.
    ///  .me: 저장되어있는 userDefaults로부터 userID를 받아온다.
    ///  .user: 다른 repository로부터 userID를 받아온다.
    func fetchUserProfile(target: ProfileTarget) async throws(RepositoryError) -> Profile
    func fetchGenrePreferences(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference]
    /// 키워드 매핑을 위해 캐시된 키워드 목록을 전달받는다.
    func fetchNovelPreferences(_ target: ProfileTarget, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelPreference
    
    func fetchProfileCharacters() async throws(RepositoryError) -> [ProfileCharacter]
    
    /// userDefaults에 저장된 닉네임, 프로필캐릭터ID를 가져온다.
    /// 서버 api를 통해 소개글, 선택한 선호 장르를 가져온다.
    func loadInitialProfile() async throws(RepositoryError) -> ProfileDraft
    /// 수정된 닉네임, 프로필 캐릭터 ID를 userDefaults에 저장
    func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError)
}
