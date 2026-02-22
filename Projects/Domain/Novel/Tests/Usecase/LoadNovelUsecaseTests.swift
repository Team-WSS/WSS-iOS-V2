//
//  LoadNovelUsecaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain
import NovelDomainTesting

@Suite
struct LoadNovelUsecaseTests {

    @Test("작품 정보를 성공적으로 불러온다")
    func loadNovelSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeNovelInformation()
        mock.fetchNovelResult = .success(expected)

        let usecase = DefaultLoadNovelUsecase(novelRepository: mock)
        let novelID = NovelID(1)

        let result = try await usecase.execute(id: novelID)

        #expect(result.novel.id == expected.novel.id)
        #expect(result.description == expected.description)
        #expect(mock.fetchedNovelIDs.last == novelID)
        #expect(mock.fetchedNovelIDs.count == 1)
    }

    @Test("작품 조회에 실패하면 에러를 던진다")
    func loadNovelFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchNovelResult = .failure(TestError.networkFail)

        let usecase = DefaultLoadNovelUsecase(novelRepository: mock)

        await #expect(throws: TestError.networkFail) {
            try await usecase.execute(id: NovelID(1))
        }
    }
}

extension LoadNovelUsecaseTests {

    private enum TestError: Error { case networkFail }

    private func makeNovel() -> Novel {
        Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "전지적 독자 시점",
            author: ["싱숑"],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: true
        )
    }

    private func makeNovelInformation() -> NovelInformation {
        NovelInformation(
            novel: makeNovel(),
            feedCount: 4,
            genre: .BL,
            publicationStatus: .completed,
            userReview: nil,
            description: "재밌는 소설입니다.",
            platforms: [],
            attractivePoints: [.worldview, .character],
            keywords: [Keyword(id: 1, name: "이세계")],
            readStatusCount: [.watching: 10, .watched: 30]
        )
    }
}
