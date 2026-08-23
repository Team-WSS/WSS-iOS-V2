//
//  LoadMyLibraryUseCaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain
import BaseDomainTesting

@Suite
struct LoadMyLibraryUseCaseTests {

    @Test("내 서재 목록을 정상적으로 불러온다")
    func loadMyLibrarySuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeLibraryPage()
        mock.fetchMyLibraryResult = .success((expected, 2))

        let usecase = makeUseCase(novelRepository: mock)

        let result = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)

        #expect(result.0.items.count == expected.items.count)
        #expect(result.0.hasNext == expected.hasNext)
        #expect(mock.fetchedMyLibraryFilters.count == 1)
    }

    @Test("내 서재 조회 결과에 전체 작품 수가 포함된다")
    func loadMyLibraryReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 37))

        let usecase = makeUseCase(novelRepository: mock)
        let result = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)

        #expect(result.1 == 37)
    }

    @Test("필터 조건이 저장소에 그대로 전달된다")
    func filterIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)
        var filter = MyLibraryFilter()
        filter.addReadingStatus(.watching)
        filter.addGenre(.fantasy)

        _ = try await usecase.execute(filter: filter, cursor: nil, size: 20)

        let passedFilter = mock.fetchedMyLibraryFilters.last
        #expect(passedFilter?.readingStatus == [.watching])
        #expect(passedFilter?.genres == [.fantasy])
    }

    @Test("커서가 저장소에 그대로 전달된다")
    func cursorIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)

        _ = try await usecase.execute(filter: MyLibraryFilter(), cursor: "cursor-42", size: 20)

        #expect(mock.fetchedMyLibraryCursors.last == "cursor-42")
    }

    @Test("요청 개수(size)가 저장소에 그대로 전달된다")
    func sizeIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)

        // 재진입 갱신은 "보고 있던 개수만큼" 한 번에 받으므로 페이지 크기가 고정이 아니다.
        _ = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 47)

        #expect(mock.fetchedMyLibrarySizes.last == 47)
    }

    @Test("첫 페이지 조회는 커서 없이(nil) 저장소에 전달된다")
    func firstPagePassesNilCursor() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = makeUseCase(novelRepository: mock)

        _ = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)

        #expect(mock.fetchedMyLibraryCursors.last == .some(nil))
    }

    @Test("키워드 캐시를 서재 저장소에 전달한다")
    func passesCachedKeywordsToRepository() async throws {
        let novelRepository = MockNovelRepository()
        novelRepository.fetchMyLibraryResult = .success((makeLibraryPage(), 3))
        let keyword = Keyword(id: KeywordID(11), name: "회귀")
        let keywordRepository = MockKeywordRepository()
        keywordRepository.fetchKeywordsResult = .success([
            KeywordGroup(category: .material, keywords: [keyword])
        ])
        let usecase = DefaultLoadMyLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: keywordRepository
        )

        _ = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)

        #expect(novelRepository.lastMyLibraryCachedKeywords == [keyword])
        #expect(keywordRepository.fetchKeywordsCallCount == 1)
    }

    @Test("키워드 캐시 조회에 실패해도 서재 목록은 빈 캐시로 정상 조회된다")
    func fallsBackToEmptyKeywordsWhenCacheFails() async throws {
        let novelRepository = MockNovelRepository()
        let expected = makeLibraryPage()
        novelRepository.fetchMyLibraryResult = .success((expected, 2))
        let keywordRepository = MockKeywordRepository()
        keywordRepository.fetchKeywordsResult = .failure(RepositoryError.networkUnavailable)
        let usecase = DefaultLoadMyLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: keywordRepository
        )

        let result = try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)

        #expect(result.0.items.count == expected.items.count)
        #expect(novelRepository.lastMyLibraryCachedKeywords == [])
        #expect(keywordRepository.fetchKeywordsCallCount == 1)
    }

    @Test("내 서재 조회에 실패하면 에러를 던진다")
    func loadMyLibraryFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .failure(RepositoryError.unknown)

        let usecase = makeUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(filter: MyLibraryFilter(), cursor: nil, size: 20)
        }
    }
}

extension LoadMyLibraryUseCaseTests {

    private func makeUseCase(novelRepository: MockNovelRepository) -> DefaultLoadMyLibraryUseCase {
        DefaultLoadMyLibraryUseCase(
            novelRepository: novelRepository,
            keywordRepository: MockKeywordRepository()
        )
    }

    private func makeLibraryPage() -> CursorPaginated<LibraryNovel> {
        CursorPaginated(
            items: [
                LibraryNovel(
                    id: NovelID(1),
                    title: "전지적 독자 시점",
                    thumbnailImage: nil,
                    rating: 4.5,
                    isInterested: true,
                    userReview: nil,
                    writtenFeeds: []
                )
            ],
            hasNext: false,
            nextCursor: nil
        )
    }
}
