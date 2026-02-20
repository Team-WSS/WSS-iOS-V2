//
//  DeleteNovelReviewUseCaseTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  DeleteNovelReviewUseCaseTests.swift
//

import Testing
import NovelReviewDomain

@Suite("DeleteNovelReviewUseCase")
struct DeleteNovelReviewUseCaseTests {

    @Test("deletes by novelID successfully")
    func deletesByID() async throws {
        let repo = MockNovelReviewRepository()
        let sut = DefaultDeleteNovelReviewUseCase(repository: repo)

        let novelID = NovelID(99)
        try await sut.execute(novelID: novelID)

        #expect(repo.deletedNovelIDs == [novelID])
    }

    @Test("propagates repository error on delete")
    func deletePropagatesError() async {
        let repo = MockNovelReviewRepository()
        repo.deleteResult = .failure(.networkUnavailable)

        let sut = DefaultDeleteNovelReviewUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(novelID: NovelID(100))
        }
    }
}