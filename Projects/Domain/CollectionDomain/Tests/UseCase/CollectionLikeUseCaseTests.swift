//
//  CollectionLikeUseCaseTests.swift
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

@Suite("CollectionLikeUseCase")
struct CollectionLikeUseCaseTests {

    @Test("좋아요를 누르면 해당 컬렉션 ID로 등록을 요청한다")
    func likeSuccess() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultCollectionLikeUseCase(collectionRepository: mock)

        try await useCase.like(id: CollectionID(31))

        #expect(mock.likedIDs == [CollectionID(31)])
        #expect(mock.unlikedIDs.isEmpty)
    }

    @Test("좋아요를 취소하면 해당 컬렉션 ID로 취소를 요청한다")
    func unlikeSuccess() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultCollectionLikeUseCase(collectionRepository: mock)

        try await useCase.unlike(id: CollectionID(31))

        #expect(mock.unlikedIDs == [CollectionID(31)])
        #expect(mock.likedIDs.isEmpty)
    }

    @Test("서버가 멱등이라 같은 좋아요를 두 번 보내도 그대로 두 번 요청한다")
    func likeIsIdempotentOnServer() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultCollectionLikeUseCase(collectionRepository: mock)

        try await useCase.like(id: CollectionID(31))
        try await useCase.like(id: CollectionID(31))

        #expect(mock.likedIDs == [CollectionID(31), CollectionID(31)])
    }

    @Test("볼 수 없는 컬렉션에 좋아요를 누르면 forbidden을 전달한다")
    func likeForbidden() async {
        let mock = MockCollectionRepository()
        mock.likeCollectionResult = .failure(.forbidden)
        let useCase = DefaultCollectionLikeUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.forbidden) {
            try await useCase.like(id: CollectionID(31))
        }
    }

    @Test("좋아요 취소에 실패하면 에러를 그대로 전달한다")
    func unlikeFailure() async {
        let mock = MockCollectionRepository()
        mock.unlikeCollectionResult = .failure(.networkUnavailable)
        let useCase = DefaultCollectionLikeUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.unlike(id: CollectionID(31))
        }
    }
}
