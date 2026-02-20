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
import BaseDomain

@Suite("DeleteNovelReviewUseCase")
struct DeleteNovelReviewUseCaseTests {

    @Test("주어진 작품 ID로 작품 평가를 삭제한다")
    func deletesByID() async throws {
        let repo = MockNovelReviewRepository()
        let sut = DefaultDeleteNovelReviewUseCase(repository: repo)

        let novelID = NovelID(99)
        try await sut.execute(novelID: novelID)

        #expect(repo.deletedNovelIDs == [novelID])
    }

    @Test("삭제 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func deletePropagatesError() async {
        let repo = MockNovelReviewRepository()
        repo.deleteResult = .failure(.networkUnavailable)

        let sut = DefaultDeleteNovelReviewUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(novelID: NovelID(100))
        }
    }
}
