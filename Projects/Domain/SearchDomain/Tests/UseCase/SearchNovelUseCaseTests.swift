//
//  SearchNovelUseCaseTests.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SearchDomain
import SearchDomainTesting
import BaseDomain

@Suite
struct SearchNovelUseCaseTests {

    // MARK: - Text Search

    @Test("텍스트로 소설을 검색할 수 있다")
    func searchByTextSuccess() async throws {
        let mock = MockSearchNovelRepository()
        let expected = Paginated(items: [makeNovel()], hasNext: false)
        mock.searchByTextResult = .success((expected, 2))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let result = try await usecase.searchByText("전지적", page: 0)

        #expect(result.0.items.count == 1)
        #expect(result.0.items.first?.title == "전지적 독자 시점")
        #expect(mock.searchByTextCallCount == 1)
        #expect(mock.lastSearchQuery == "전지적")
    }

    @Test("텍스트 검색은 다음 페이지 번호를 그대로 전달한다")
    func searchByTextForwardsPage() async throws {
        let mock = MockSearchNovelRepository()
        mock.searchByTextResult = .success((Paginated(items: [makeNovel()], hasNext: true), 42))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        _ = try await usecase.searchByText("전지적", page: 2)

        #expect(mock.lastSearchTextPage == 2)
    }

    @Test("텍스트 검색 결과에 전체 작품 수가 포함된다")
    func searchByTextReturnsCount() async throws {
        let mock = MockSearchNovelRepository()
        mock.searchByTextResult = .success((Paginated(items: [makeNovel()], hasNext: false), 42))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let result = try await usecase.searchByText("전지적", page: 0)

        #expect(result.1 == 42)
    }

    @Test("텍스트 검색에 실패하면 에러를 던진다")
    func searchByTextFailureThrows() async {
        let mock = MockSearchNovelRepository()
        mock.searchByTextResult = .failure(RepositoryError.unknown)

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.searchByText("전지적", page: 0)
        }

        #expect(mock.searchByTextCallCount == 1)
    }

    // MARK: - Filter Search

    @Test("필터로 소설을 검색할 수 있다")
    func searchByFilterSuccess() async throws {
        let mock = MockSearchNovelRepository()
        let expected = Paginated(items: [makeNovel(), makeNovel(id: 2, title: "나 혼자만 레벨업")], hasNext: true)
        mock.searchByFilterResult = .success((expected, 2))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let filter = SearchFilter(
            genres: [.fantasy],
            publicationStatus: .completed,
            keywords: []
        )

        let result = try await usecase.searchByFilter(filter, page: 0)

        #expect(result.0.items.count == 2)
        #expect(result.0.hasNext == true)
        #expect(mock.searchByFilterCallCount == 1)
    }

    @Test("필터 검색은 다음 페이지 번호를 그대로 전달한다")
    func searchByFilterForwardsPage() async throws {
        let mock = MockSearchNovelRepository()
        mock.searchByFilterResult = .success((Paginated(items: [makeNovel()], hasNext: true), 42))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let filter = SearchFilter(genres: [], publicationStatus: nil, keywords: [])
        _ = try await usecase.searchByFilter(filter, page: 3)

        #expect(mock.lastSearchFilterPage == 3)
    }

    @Test("필터 검색 결과에 전체 작품 수가 포함된다")
    func searchByFilterReturnsCount() async throws {
        let mock = MockSearchNovelRepository()
        mock.searchByFilterResult = .success((Paginated(items: [makeNovel()], hasNext: true), 128))

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let filter = SearchFilter(genres: [], publicationStatus: nil, keywords: [])
        let result = try await usecase.searchByFilter(filter, page: 0)

        #expect(result.1 == 128)
    }

    @Test("필터 검색에 실패하면 에러를 던진다")
    func searchByFilterFailureThrows() async {
        let mock = MockSearchNovelRepository()
        mock.searchByFilterResult = .failure(RepositoryError.unknown)

        let usecase = DefaultSearchNovelUseCase(searchNovelRepository: mock)
        let filter = SearchFilter(
            genres: [],
            publicationStatus: nil,
            keywords: []
        )

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.searchByFilter(filter, page: 0)
        }

        #expect(mock.searchByFilterCallCount == 1)
    }
}

extension SearchNovelUseCaseTests {
    private func makeNovel(
        id: Int = 1,
        title: String = "전지적 독자 시점"
    ) -> Novel {
        Novel(
            id: NovelID(id),
            thumbnailImage: nil,
            title: title,
            authors: ["싱숑"],
            genres: [.fantasy],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: nil
        )
    }
}
