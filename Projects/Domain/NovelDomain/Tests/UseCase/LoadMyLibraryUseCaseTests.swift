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

@Suite
struct LoadMyLibraryUseCaseTests {

    @Test("내 서재 목록을 정상적으로 불러온다")
    func loadMyLibrarySuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeLibraryPage()
        mock.fetchMyLibraryResult = .success((expected, 2))

        let usecase = DefaultLoadMyLibraryUseCase(novelRepository: mock)
        let filter = makeFilter()

        let result = try await usecase.execute(filter)

        #expect(result.0.items.count == expected.items.count)
        #expect(result.0.hasNext == expected.hasNext)
        #expect(mock.fetchedMyLibraryFilters.count == 1)
    }

    @Test("내 서재 조회 결과에 전체 작품 수가 포함된다")
    func loadMyLibraryReturnsCount() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 37))

        let usecase = DefaultLoadMyLibraryUseCase(novelRepository: mock)
        let result = try await usecase.execute(makeFilter())

        #expect(result.1 == 37)
    }

    @Test("필터 조건이 결과에 전달된다")
    func filterIsPassedToRepository() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .success((makeLibraryPage(), 3))

        let usecase = DefaultLoadMyLibraryUseCase(novelRepository: mock)
        var filter = makeFilter()
        filter.addReadingStatus(.watching)
        filter.addAttractivePoint(.worldview)

        _ = try await usecase.execute(filter)

        let passedFilter = mock.fetchedMyLibraryFilters.last
        #expect(passedFilter?.readingStatus == [.watching])
        #expect(passedFilter?.attractivePoint == [.worldview])
    }

    @Test("내 서재 조회에 실패하면 에러를 던진다")
    func loadMyLibraryFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryResult = .failure(RepositoryError.unknown)

        let usecase = DefaultLoadMyLibraryUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(makeFilter())
        }
    }
}

extension LoadMyLibraryUseCaseTests {

    private func makeFilter() -> LibraryFilter {
        LibraryFilter(readingStatus: [], attractivePoint: [], ratingThreshold: nil)
    }

    private func makeLibraryPage() -> Paginated<LibraryNovel> {
        Paginated(
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
            hasNext: false
        )
    }
}
