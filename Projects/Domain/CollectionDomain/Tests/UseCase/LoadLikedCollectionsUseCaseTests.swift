//
//  LoadLikedCollectionsUseCaseTests.swift
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

@Suite("LoadLikedCollectionsUseCase")
struct LoadLikedCollectionsUseCaseTests {

    @Test("좋아요한 컬렉션 목록과 전체 개수를 함께 불러온다")
    func loadSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.fetchLikedCollectionsResult = .success((makePage(cardCount: 3), 3))
        let useCase = DefaultLoadLikedCollectionsUseCase(collectionRepository: mock)

        let (page, totalCount) = try await useCase.execute(cursor: nil, size: 10)

        #expect(page.items.count == 3)
        #expect(totalCount == 3)
    }

    @Test("좋아요한 목록도 커서를 그대로 넘겨 다음 페이지를 잇는다")
    func passesCursorAsIs() async throws {
        let mock = MockCollectionRepository()
        mock.fetchLikedCollectionsResult = .success((makePage(), 0))
        let useCase = DefaultLoadLikedCollectionsUseCase(collectionRepository: mock)

        _ = try await useCase.execute(cursor: "server-issued-cursor", size: 20)

        #expect(mock.fetchedLikedRequests.last?.cursor == "server-issued-cursor")
        #expect(mock.fetchedLikedRequests.last?.size == 20)
    }

    @Test("조회에 실패하면 에러를 그대로 전달한다")
    func loadFailure() async {
        let mock = MockCollectionRepository()
        mock.fetchLikedCollectionsResult = .failure(.authenticationRequired)
        let useCase = DefaultLoadLikedCollectionsUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await useCase.execute(cursor: nil, size: 10)
        }
    }
}

private extension LoadLikedCollectionsUseCaseTests {
    func makePage(cardCount: Int = 1) -> CursorPaginated<CollectionCard> {
        CursorPaginated(
            items: (0..<cardCount).map { index in
                CollectionCard(
                    id: CollectionID(index),
                    name: "컬렉션",
                    description: nil,
                    novelCount: 5,
                    isPrivate: false,
                    recentNovels: []
                )
            },
            hasNext: false,
            nextCursor: nil
        )
    }
}
