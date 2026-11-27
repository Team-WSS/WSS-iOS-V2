//
//  LoadNovelPreferencesUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 11/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain
import BaseDomainTesting
import ProfileDomain
import ProfileDomainTesting

// 서버는 선호 키워드를 이름으로만 준다. 앱은 전체 키워드 목록에서 같은 이름을 찾아 키워드로 바꾸므로,
// 불러오는 UseCase는 모든 카테고리의 키워드를 넘겨야 한다.
// 카테고리를 둘로 나눠 둬서, 한 카테고리의 키워드만 넘기면 저장소가 답을 찾지 못한다.
private let keywordGroups = [
    KeywordGroup(category: .material, keywords: [
        Keyword(id: KeywordID(11), name: "회귀")
    ]),
    KeywordGroup(category: .character, keywords: [
        Keyword(id: KeywordID(21), name: "먼치킨"),
        Keyword(id: KeywordID(22), name: "사이다")
    ])
]
private let allKeywords = Set(keywordGroups.flatMap(\.keywords))

@Suite("선호 작품 불러오기")
struct LoadNovelPreferencesUseCaseTests {

    @Test("선호 작품을 불러올 때 모든 카테고리의 키워드를 넘긴다")
    func passesKeywordsOfAllCategories() async throws {
        let profileRepository = MockProfileRepository()
        profileRepository.novelPreferencesByCachedKeywords = [
            allKeywords: NovelPreference(attractivePoints: [.vibe], keywords: [])
        ]
        let useCase = DefaultLoadNovelPreferencesUseCase(
            profileRepository: profileRepository,
            loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .success(keywordGroups))
        )

        let preference = try await useCase.execute(.me)

        #expect(preference.attractivePoints == [.vibe])
    }

    @Test("전체 키워드를 못 불러와도 선호 작품은 불러온다")
    func loadsWithoutKeywords() async throws {
        let profileRepository = MockProfileRepository()
        profileRepository.novelPreferencesByCachedKeywords = [
            []: NovelPreference(attractivePoints: [.vibe], keywords: [])
        ]
        let useCase = DefaultLoadNovelPreferencesUseCase(
            profileRepository: profileRepository,
            loadTotalKeywordsUseCase: MockLoadTotalKeywordsUseCase(result: .failure(.networkUnavailable))
        )

        let preference = try await useCase.execute(.me)

        #expect(preference.attractivePoints == [.vibe])
    }
}
