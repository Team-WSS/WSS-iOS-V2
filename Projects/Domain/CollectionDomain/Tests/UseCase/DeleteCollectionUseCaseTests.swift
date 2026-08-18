//
//  DeleteCollectionUseCaseTests.swift
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

@Suite("DeleteCollectionUseCase")
struct DeleteCollectionUseCaseTests {

    @Test("삭제하려는 컬렉션 ID가 전달된다")
    func deleteSuccess() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultDeleteCollectionUseCase(collectionRepository: mock)

        try await useCase.execute(id: CollectionID(31))

        #expect(mock.deletedIDs == [CollectionID(31)])
    }

    @Test("삭제에 실패하면 에러를 그대로 전달한다")
    func deleteFailure() async {
        let mock = MockCollectionRepository()
        mock.deleteCollectionResult = .failure(.notFound)
        let useCase = DefaultDeleteCollectionUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.notFound) {
            try await useCase.execute(id: CollectionID(31))
        }
    }
}
