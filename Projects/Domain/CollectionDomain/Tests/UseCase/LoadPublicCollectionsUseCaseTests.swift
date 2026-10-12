//
//  LoadPublicCollectionsUseCaseTests.swift
//  CollectionDomainTests
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation

@testable import CollectionDomain
import CollectionDomainTesting
import BaseDomain

@Suite("LoadPublicCollectionsUseCase")
struct LoadPublicCollectionsUseCaseTests {

    @Test("공개 컬렉션 목록을 작성자와 함께 불러온다")
    func loadSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.fetchPublicCollectionsResult = .success(makePage(cardCount: 3))
        let useCase = DefaultLoadPublicCollectionsUseCase(collectionRepository: mock)

        let page = try await useCase.execute(cursor: nil, size: 10)

        #expect(page.items.count == 3)
        #expect(page.items.first?.owner.nickname == "작성자")
    }

    @Test("서버가 준 순서를 바꾸지 않고 그대로 돌려준다")
    func preservesServerOrder() async throws {
        let mock = MockCollectionRepository()
        mock.fetchPublicCollectionsResult = .success(makePage(cardCount: 3))
        let useCase = DefaultLoadPublicCollectionsUseCase(collectionRepository: mock)

        let page = try await useCase.execute(cursor: nil, size: 10)

        #expect(page.items.map(\.id) == [CollectionID(0), CollectionID(1), CollectionID(2)])
    }

    @Test("커서와 개수를 그대로 넘겨 다음 페이지를 잇는다")
    func passesCursorAndSizeAsIs() async throws {
        let mock = MockCollectionRepository()
        mock.fetchPublicCollectionsResult = .success(makePage())
        let useCase = DefaultLoadPublicCollectionsUseCase(collectionRepository: mock)

        _ = try await useCase.execute(cursor: "server-issued-cursor", size: 20)

        #expect(mock.fetchedPublicRequests.count == 1)
        #expect(mock.fetchedPublicRequests.last?.cursor == "server-issued-cursor")
        #expect(mock.fetchedPublicRequests.last?.size == 20)
    }

    @Test("다음 페이지 여부와 커서를 그대로 전달한다")
    func passesPagingInfo() async throws {
        let mock = MockCollectionRepository()
        mock.fetchPublicCollectionsResult = .success(makePage(hasNext: true, nextCursor: "next"))
        let useCase = DefaultLoadPublicCollectionsUseCase(collectionRepository: mock)

        let page = try await useCase.execute(cursor: nil, size: 10)

        #expect(page.hasNext)
        #expect(page.nextCursor == "next")
    }

    @Test("조회에 실패하면 에러를 그대로 전달한다")
    func loadFailure() async {
        let mock = MockCollectionRepository()
        mock.fetchPublicCollectionsResult = .failure(.networkUnavailable)
        let useCase = DefaultLoadPublicCollectionsUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.execute(cursor: nil, size: 10)
        }
    }
}

private extension LoadPublicCollectionsUseCaseTests {
    func makePage(
        cardCount: Int = 1,
        hasNext: Bool = false,
        nextCursor: String? = nil
    ) -> CursorPaginated<PublicCollectionCard> {
        CursorPaginated(
            items: (0..<cardCount).map { index in
                PublicCollectionCard(
                    id: CollectionID(index),
                    name: "컬렉션",
                    description: nil,
                    novelCount: 5,
                    recentNovels: [],
                    owner: Author(userId: UserID(index), nickname: "작성자", profileImage: nil)
                )
            },
            hasNext: hasNext,
            nextCursor: nextCursor
        )
    }
}
