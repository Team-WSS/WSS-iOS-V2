//
//  SearchNovelUsecaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain

@Suite
struct SearchNovelUsecaseTests {

    // MARK: - Text Search

    @Test func `텍스트로 소설을 검색할 수 있다.`() async throws {
        let mock = MockNovelRepository()
        let expected = Paginated(items: [makeNovel()], hasNext: false)
        mock.searchByTextResult = .success(expected)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let result = try await usecase.searchByText("전지적")

        #expect(result.items.count == 1)
        #expect(result.items.first?.title == "전지적 독자 시점")
        #expect(mock.searchByTextCallCount == 1)
        #expect(mock.lastSearchQuery == "전지적")
    }

    @Test func `텍스트 검색에 실패하면 에러를 던진다.`() async {
        let mock = MockNovelRepository()
        mock.searchByTextResult = .failure(TestError.searchFail)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)

        await #expect(throws: TestError.searchFail) {
            try await usecase.searchByText("전지적")
        }

        #expect(mock.searchByTextCallCount == 1)
    }

    // MARK: - Filter Search

    @Test func `필터로 소설을 검색할 수 있다.`() async throws {
        let mock = MockNovelRepository()
        let expected = Paginated(items: [makeNovel(), makeNovel(id: 2, title: "나 혼자만 레벨업")], hasNext: true)
        mock.searchByFilterResult = .success(expected)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let filter = NovelSearchFilter(
            genres: [.fantasy],
            completionStatus: .completed,
            ratingThreshold: .over4_0,
            keywords: []
        )

        let result = try await usecase.searchByFilter(filter)

        #expect(result.items.count == 2)
        #expect(result.hasNext == true)
        #expect(mock.searchByFilterCallCount == 1)
    }

    @Test func `필터 검색에 실패하면 에러를 던진다.`() async {
        let mock = MockNovelRepository()
        mock.searchByFilterResult = .failure(TestError.searchFail)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let filter = NovelSearchFilter(
            genres: [],
            completionStatus: nil,
            ratingThreshold: nil,
            keywords: []
        )

        await #expect(throws: TestError.searchFail) {
            try await usecase.searchByFilter(filter)
        }

        #expect(mock.searchByFilterCallCount == 1)
    }
}

extension SearchNovelUsecaseTests {

    private enum TestError: Error { case searchFail }

    private func makeNovel(
        id: Int = 1,
        title: String = "전지적 독자 시점"
    ) -> Novel {
        Novel(
            id: NovelID(id),
            thumbnailImage: ImageWrapper(identifier: "\(id)"),
            title: title,
            author: ["싱숑"],
            interestCount: 100,
            novelRating: 4.5,
            novelRatingCount: 50
        )
    }
}
