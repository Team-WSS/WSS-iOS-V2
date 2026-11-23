//
//  MockProfileRepository.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import ProfileDomain
import BaseDomain

/// 프로필 저장소 가짜 객체.
/// - 선호 작품 조회는 **넘겨받은 키워드 캐시마다** 답을 정해 둔다(Stub) — 정해 두지 않은 캐시로 부르면 `.notFound`.
///   그래서 UseCase가 키워드를 잘못 넘기면 결과가 달라진다. 키워드 순서는 따지지 않는다(`Set`).
/// - 기본 정보 동기화(명령)는 호출 횟수를 센다(Mock) — SplashData 런치 작업 테스트가 쓴다.
/// - 나머지 조회는 쓰는 테스트가 없어 `.notFound`, 나머지 명령은 아무것도 하지 않는다 — 필요해지면 그때 더한다.
public final class MockProfileRepository: ProfileRepository {
    public var novelPreferencesByCachedKeywords: [Set<Keyword>: NovelPreference] = [:]
    public private(set) var syncUserBasicInfoCallCount = 0

    public init() {}

    public func syncUserBasicInfo() async throws(RepositoryError) {
        syncUserBasicInfoCallCount += 1
    }

    public func fetchNovelPreferences(
        _ target: ProfileTarget,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> NovelPreference {
        guard let preference = novelPreferencesByCachedKeywords[Set(cachedKeywords)] else { throw .notFound }
        return preference
    }

    public func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool { throw .notFound }

    public func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError) {}

    public func loadAccountInfoDraft() async throws(RepositoryError) -> AccountInfoDraft { throw .notFound }

    public func saveAccountInfo(_ info: AccountInfoDraft) async throws(RepositoryError) {}

    public func loadLocalGenderAndBirth() async throws(RepositoryError) -> AccountInfoDraft { throw .notFound }

    public func loadProfileVisibility() async throws(RepositoryError) -> ProfileVisibility { throw .notFound }

    public func updateProfileVisibility(_ visibility: ProfileVisibility) async throws(RepositoryError) {}

    public func fetchUserProfile(target: ProfileTarget) async throws(RepositoryError) -> Profile { throw .notFound }

    public func fetchGenrePreferences(_ target: ProfileTarget) async throws(RepositoryError) -> [GenrePreference] {
        throw .notFound
    }

    public func fetchProfileCharacters() async throws(RepositoryError) -> [ProfileCharacter] { throw .notFound }

    public func loadInitialProfile() async throws(RepositoryError) -> ProfileDraft { throw .notFound }

    public func updateProfile(_ profile: ProfileDraft) async throws(RepositoryError) {}
}
