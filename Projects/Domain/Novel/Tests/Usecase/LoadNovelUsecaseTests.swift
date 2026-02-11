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

@Suite
struct LoadNovelUsecaseTests {

    @Test func `소설 상세와 정보를 성공적으로 불러온다.`() async throws {
        let mock = MockNovelRepository()
        let expectedDetail = makeNovelDetail()
        let expectedInfo = makeNovelInformation()
        mock.fetchDetailResult = .success(expectedDetail)
        mock.fetchInformationResult = .success(expectedInfo)

        let usecase = DefaultLoadNovelUsecase(novelRepository: mock)
        let novelID = NovelID(1)

        let result = try await usecase.execute(id: novelID)

        #expect(result.detail.novel.id == expectedDetail.novel.id)
        #expect(result.information.description == expectedInfo.description)
        #expect(mock.fetchDetailCallCount == 1)
        #expect(mock.fetchInformationCallCount == 1)
        #expect(mock.lastFetchedDetailID == novelID)
        #expect(mock.lastFetchedInformationID == novelID)
    }

    @Test func `소설 상세 조회에 실패하면 에러를 던진다.`() async {
        let mock = MockNovelRepository()
        mock.fetchDetailResult = .failure(TestError.networkFail)
        mock.fetchInformationResult = .success(makeNovelInformation())

        let usecase = DefaultLoadNovelUsecase(novelRepository: mock)

        await #expect(throws: TestError.networkFail) {
            try await usecase.execute(id: NovelID(1))
        }
    }

    @Test func `소설 정보 조회에 실패하면 에러를 던진다.`() async {
        let mock = MockNovelRepository()
        mock.fetchDetailResult = .success(makeNovelDetail())
        mock.fetchInformationResult = .failure(TestError.networkFail)

        let usecase = DefaultLoadNovelUsecase(novelRepository: mock)

        await #expect(throws: TestError.networkFail) {
            try await usecase.execute(id: NovelID(1))
        }
    }
}

extension LoadNovelUsecaseTests {

    private enum TestError: Error { case networkFail }

    private func makeNovelDetail() -> NovelDetail {
        NovelDetail(
            novel: Novel(
                id: NovelID(1),
                thumbnailImage: ImageWrapper(identifier: "1"),
                title: "전지적 독자 시점",
                author: ["싱숑"],
                interestCount: 100,
                novelRating: 4.5,
                novelRatingCount: 50
            ),
            genres: [.fantasy],
            isCompleted: true,
            feedCount: 10,
            userNovelRating: 4.0,
            userReadStatus: .watched,
            userReadStartDate: nil,
            userReadEndDate: nil,
            isUserInterested: true
        )
    }

    private func makeNovelInformation() -> NovelInformation {
        NovelInformation(
            description: "재밌는 소설입니다.",
            platforms: [],
            attractivePoints: [.worldview, .character],
            keywords: [Keyword(id: 1, name: "이세계")],
            readStatusCount: [.watching: 10, .watched: 30]
        )
    }
}
