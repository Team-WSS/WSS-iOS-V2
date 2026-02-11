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
    
    @Test("초안 데이터를 저장한다")
    func savesDraftSuccessfully() async throws {
        let repo = MockNovelReviewRepository()
        let draft = makeDraft()

        let sut = DefaultSaveNovelReviewUseCase(repository: repo)

        try await sut.execute(draft: draft)

        #expect(repo.savedDrafts == [draft])
    }

    @Test("저장 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelReviewRepository()
        repo.saveResult = .failure(.serverUnavailable)

        let sut = DefaultSaveNovelReviewUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(draft: makeDraft())
        }
    }
}
