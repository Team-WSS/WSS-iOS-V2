//
//  SaveNovelReviewUseCaseTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  SaveNovelReviewUseCaseTests.swift
//

import Testing
import NovelReviewDomain

@Suite("SaveNovelReviewUseCase")
struct SaveNovelReviewUseCaseTests {
    
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
    
    @Test("saves draft successfully")
    func savesDraftSuccessfully() async throws {
        let repo = MockNovelReviewRepository()
        let draft = makeDraft()

        let sut = DefaultSaveNovelReviewUseCase(repository: repo)

        try await sut.execute(draft: draft)

        #expect(repo.savedDrafts == [draft])
    }

    @Test("propagates repository error")
    func propagatesRepositoryError() async {
        let repo = MockNovelReviewRepository()
        repo.saveResult = .failure(.serverUnavailable)

        let sut = DefaultSaveNovelReviewUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(draft: makeDraft())
        }
    }
}
