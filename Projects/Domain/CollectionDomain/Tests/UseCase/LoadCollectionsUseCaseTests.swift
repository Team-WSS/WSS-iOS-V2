//
//  LoadCollectionsUseCaseTests.swift
//  CollectionDomainTests
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation

@testable import CollectionDomain
import CollectionDomainTesting
import BaseDomain

@Suite("LoadCollectionsUseCase")
struct LoadCollectionsUseCaseTests {

    @Test("컬렉션 목록과 전체 개수를 함께 불러온다")
    func loadSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionsResult = .success((makePage(cardCount: 2, hasNext: true, nextCursor: "c1"), 12))
        let useCase = DefaultLoadCollectionsUseCase(collectionRepository: mock)

        let (page, totalCount) = try await useCase.execute(userID: UserID(1), cursor: nil, size: 10)

        #expect(page.items.count == 2)
        #expect(page.hasNext)
        #expect(page.nextCursor == "c1")
        #expect(totalCount == 12)
    }

    @Test("첫 페이지는 커서 없이 요청한다")
    func firstPageHasNoCursor() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionsResult = .success((makePage(), 0))
        let useCase = DefaultLoadCollectionsUseCase(collectionRepository: mock)

        _ = try await useCase.execute(userID: UserID(1), cursor: nil, size: 10)

        #expect(mock.fetchedCollectionRequests.last?.cursor == nil)
    }

    @Test("다음 페이지는 직전 응답이 준 커서를 그대로 넘긴다")
    func nextPagePassesCursorAsIs() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionsResult = .success((makePage(), 0))
        let useCase = DefaultLoadCollectionsUseCase(collectionRepository: mock)

        _ = try await useCase.execute(userID: UserID(1), cursor: "server-issued-cursor", size: 10)

        #expect(mock.fetchedCollectionRequests.last?.cursor == "server-issued-cursor")
    }

    @Test("마지막 페이지에는 다음 커서가 없다")
    func lastPageHasNoNextCursor() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionsResult = .success((makePage(hasNext: false, nextCursor: nil), 2))
        let useCase = DefaultLoadCollectionsUseCase(collectionRepository: mock)

        let (page, _) = try await useCase.execute(userID: UserID(1), cursor: "c1", size: 10)

        #expect(page.hasNext == false)
        #expect(page.nextCursor == nil)
    }

    @Test("조회에 실패하면 에러를 그대로 전달한다")
    func loadFailure() async {
        let mock = MockCollectionRepository()
        mock.fetchCollectionsResult = .failure(.forbidden)
        let useCase = DefaultLoadCollectionsUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.forbidden) {
            try await useCase.execute(userID: UserID(1), cursor: nil, size: 10)
        }
    }
}

private extension LoadCollectionsUseCaseTests {
    func makePage(
        cardCount: Int = 1,
        hasNext: Bool = false,
        nextCursor: String? = nil
    ) -> CursorPaginated<CollectionCard> {
        CursorPaginated(
            items: (0..<cardCount).map { index in
                CollectionCard(
                    id: CollectionID(index),
                    name: "컬렉션",
                    description: nil,
                    novelCount: 10,
                    isPrivate: false,
                    recentNovels: []
                )
            },
            hasNext: hasNext,
            nextCursor: nextCursor
        )
    }
}
