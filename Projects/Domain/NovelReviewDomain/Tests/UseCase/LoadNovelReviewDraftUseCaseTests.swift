//
//  LoadNovelReviewDraftUseCaseTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelReviewDomain
import NovelReviewDomainTesting
import BaseDomain

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
    
    @Test("주어진 작품 ID로 초안 데이터를 조회한다")
    func loadsDraftSuccessfully() async throws {
        let repo = MockNovelReviewRepository()
        let expectedDraft = makeDraft()
        repo.loadResult = .success(expectedDraft)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        let result = try await sut.execute(novelID: expectedDraft.novelID)

        #expect(repo.loadedNovelID == expectedDraft.novelID)
        #expect(result == expectedDraft)
    }

    @Test("해당 작품의 초안이 없으면 nil을 반환한다")
    func returnsNilWhenNoDraftExists() async throws {
        let repo = MockNovelReviewRepository()
        repo.loadResult = .success(nil)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        let result = try await sut.execute(novelID: NovelID(1))

        #expect(result == nil)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelReviewRepository()
        repo.loadResult = .failure(.networkUnavailable)

        let sut = DefaultLoadNovelReviewDraftUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(novelID: NovelID(1))
        }
    }
}
