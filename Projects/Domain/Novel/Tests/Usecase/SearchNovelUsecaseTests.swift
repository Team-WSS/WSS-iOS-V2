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
import NovelDomainTesting

@Suite
struct SearchNovelUsecaseTests {

    // MARK: - Text Search

    @Test("텍스트로 소설을 검색할 수 있다")
    func searchByTextSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = Paginated(items: [makeNovel()], hasNext: false)
        mock.searchByTextResult = .success((expected, 2))

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let result = try await usecase.searchByText("전지적")

        #expect(result.0.items.count == 1)
        #expect(result.0.items.first?.title == "전지적 독자 시점")
        #expect(mock.searchByTextCallCount == 1)
        #expect(mock.lastSearchQuery == "전지적")
    }

    @Test("텍스트 검색 결과에 전체 작품 수가 포함된다")
    func searchByTextReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.searchByTextResult = .success((Paginated(items: [makeNovel()], hasNext: false), 42))

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let result = try await usecase.searchByText("전지적")

        #expect(result.1 == 42)
    }

    @Test("텍스트 검색에 실패하면 에러를 던진다")
    func searchByTextFailureThrows() async {
        let mock = MockNovelRepository()
        mock.searchByTextResult = .failure(TestError.searchFail)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)

        await #expect(throws: TestError.searchFail) {
            try await usecase.searchByText("전지적")
        }

        #expect(mock.searchByTextCallCount == 1)
    }

    // MARK: - Filter Search

    @Test("필터로 소설을 검색할 수 있다")
    func searchByFilterSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = Paginated(items: [makeNovel(), makeNovel(id: 2, title: "나 혼자만 레벨업")], hasNext: true)
        mock.searchByFilterResult = .success((expected, 2))

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let filter = NovelSearchFilter(
            genres: [.fantasy],
            publicationStatus: .completed,
            ratingThreshold: .over4_0,
            keywords: []
        )

        let result = try await usecase.searchByFilter(filter)

        #expect(result.0.items.count == 2)
        #expect(result.0.hasNext == true)
        #expect(mock.searchByFilterCallCount == 1)
    }

    @Test("필터 검색 결과에 전체 작품 수가 포함된다")
    func searchByFilterReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.searchByFilterResult = .success((Paginated(items: [makeNovel()], hasNext: true), 128))

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let filter = NovelSearchFilter(genres: [], publicationStatus: nil, ratingThreshold: nil, keywords: [])
        let result = try await usecase.searchByFilter(filter)

        #expect(result.1 == 128)
    }

    @Test("필터 검색에 실패하면 에러를 던진다")
    func searchByFilterFailureThrows() async {
        let mock = MockNovelRepository()
        mock.searchByFilterResult = .failure(TestError.searchFail)

        let usecase = DefaultSearchNovelUsecase(novelRepository: mock)
        let filter = NovelSearchFilter(
            genres: [],
            publicationStatus: nil,
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
            thumbnailImage: nil,
            title: title,
            author: ["싱숑"],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: nil
        )
    }
}
