//
//  LoadNovelReviewDraftUseCaseTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  LoadNovelReviewDraftUseCaseTests.swift
//

import Testing
import NovelReviewDomain

@Suite("LoadNovelReviewDraftUseCase")
struct LoadNovelReviewDraftUseCaseTests {
    
    private func makeDraft(
        status: ReadingStatus = .watching,
        period: ReadingPeriod? = nil,
        rating: Rating? = nil,
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = []
    ) -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: NovelID(42),
            status: status,
            period: period,
            rating: rating,
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }
    
    @Test("loads draft by novelID successfully")
    func loadsDraftSuccessfully() async throws {
        let repo = MockNovelReviewRepository()
        let expectedDraft = makeDraft()
        repo.loadResult = .success(expectedDraft)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        let result = try await sut.execute(novelID: expectedDraft.novelID)

        #expect(repo.loadedNovelID == expectedDraft.novelID)
        #expect(result == expectedDraft)
    }

    @Test("returns nil when repository returns nil")
    func returnsNilWhenNoDraftExists() async throws {
        let repo = MockNovelReviewRepository()
        repo.loadResult = .success(nil)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        let result = try await sut.execute(novelID: NovelID(1))

        #expect(result == nil)
    }

    @Test("propagates repository error")
    func propagatesRepositoryError() async {
        let repo = MockNovelReviewRepository()
        repo.loadResult = .failure(.networkUnavailable)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(novelID: NovelID(1))
        }
    }
}
