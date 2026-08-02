//
//  LoadUserLibraryUseCaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain
import BaseDomainTesting

@Suite
struct LoadUserLibraryUseCaseTests {

    @Test("타유저 서재 목록을 정상적으로 불러온다")
    func loadUserLibrarySuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeLibraryPage()
        mock.fetchUserLibraryResult = .success((expected, 2))

        let usecase = makeUseCase(novelRepository: mock)
        let userID = UserID(1003)

        let result = try await usecase.execute(id: userID, filter: LibraryFilter(), cursor: nil)

        #expect(result.0.items.count == expected.items.count)
        #expect(result.0.hasNext == expected.hasNext)
        #expect(mock.fetchedUserLibraryIDs.last == userID)
        #expect(mock.fetchedUserLibraryIDs.count == 1)
    }

    @Test("타유저 서재 조회 결과에 전체 작품 수가 포함된다")
    func loadUserLibraryReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .success((makeLibraryPage(), 15))

        let usecase = makeUseCase(novelRepository: mock)
        let result = try await usecase.execute(id: UserID(1003), filter: LibraryFilter(), cursor: nil)

        #expect(result.1 == 15)
    }

    @Test("정렬 조건이 저장소에 그대로 전달된다")
    func sortTypeIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)
        var filter = LibraryFilter()
        filter.setSortType(.ratingHighest)

        _ = try await usecase.execute(id: UserID(1003), filter: filter, cursor: nil)

        #expect(mock.fetchedUserLibraryFilters.last?.sortType == .ratingHighest)
    }

    @Test("커서가 저장소에 그대로 전달된다")
    func cursorIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)

        _ = try await usecase.execute(id: UserID(1003), filter: LibraryFilter(), cursor: "cursor-42")

        #expect(mock.fetchedUserLibraryCursors.last == "cursor-42")
    }

    @Test("첫 페이지 조회는 커서 없이(nil) 저장소에 전달된다")
    func firstPagePassesNilCursor() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)

        _ = try await usecase.execute(id: UserID(1003), filter: LibraryFilter(), cursor: nil)

        #expect(mock.fetchedUserLibraryCursors.last == .some(nil))
    }

    @Test("키워드 캐시를 서재 저장소에 전달한다")
    func passesCachedKeywordsToRepository() async throws {
        let novelRepository = MockNovelRepository()
        novelRepository.fetchUserLibraryResult = .success((makeLibraryPage(), 3))
        let keyword = Keyword(id: KeywordID(11), name: "회귀")
        let keywordRepository = MockKeywordRepository()
        keywordRepository.fetchKeywordsResult = .success([
            KeywordGroup(category: .material, keywords: [keyword])
        ])
        let usecase = DefaultLoadUserLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: keywordRepository
        )

        _ = try await usecase.execute(id: UserID(1003), filter: LibraryFilter(), cursor: nil)

        #expect(novelRepository.lastUserLibraryCachedKeywords == [keyword])
        #expect(keywordRepository.fetchKeywordsCallCount == 1)
    }

    @Test("키워드 캐시 조회에 실패해도 서재 목록은 빈 캐시로 정상 조회된다")
    func fallsBackToEmptyKeywordsWhenCacheFails() async throws {
        let novelRepository = MockNovelRepository()
        let expected = makeLibraryPage()
        novelRepository.fetchUserLibraryResult = .success((expected, 2))
        let keywordRepository = MockKeywordRepository()
        keywordRepository.fetchKeywordsResult = .failure(RepositoryError.networkUnavailable)
        let usecase = DefaultLoadUserLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: keywordRepository
        )

        let result = try await usecase.execute(id: UserID(1003), filter: LibraryFilter(), cursor: nil)

        #expect(result.0.items.count == expected.items.count)
        #expect(novelRepository.lastUserLibraryCachedKeywords == [])
        #expect(keywordRepository.fetchKeywordsCallCount == 1)
    }

    @Test("타유저 서재 조회에 실패하면 에러를 던진다")
    func loadUserLibraryFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchUserLibraryResult = .failure(RepositoryError.unknown)

        let usecase = makeUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(id: UserID(1), filter: LibraryFilter(), cursor: nil)
        }
    }
}

extension LoadUserLibraryUseCaseTests {

    private func makeUseCase(novelRepository: MockNovelRepository) -> DefaultLoadUserLibraryUseCase {
        DefaultLoadUserLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: MockKeywordRepository()
        )
    }

    private func makeLibraryPage() -> CursorPaginated<LibraryNovel> {
        CursorPaginated(
            items: [
                LibraryNovel(
                    id: NovelID(1),
                    title: "어쿠스틱 러브",
                    thumbnailImage: URL(string: "https://example.com/image.jpg"),
                    rating: 3.45,
                    isInterested: false,
                    userReview: nil,
                    writtenFeeds: ["이 작품은 너무 재밌어요"]
                )
            ],
            hasNext: true,
            nextCursor: "cursor-next"
        )
    }
}
