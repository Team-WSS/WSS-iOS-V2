//
//  UpdateCollectionUseCaseTests.swift
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

@Suite("UpdateCollectionUseCase")
struct UpdateCollectionUseCaseTests {

    @Test("수정하려는 컬렉션 ID와 초안이 함께 전달된다")
    func updateSuccess() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultUpdateCollectionUseCase(collectionRepository: mock)

        try await useCase.execute(id: CollectionID(31), draft: makeDraft(name: "바뀐 이름"))

        #expect(mock.updatedRequests.last?.id == CollectionID(31))
        #expect(mock.updatedRequests.last?.draft.name == "바뀐 이름")
        #expect(mock.updatedRequests.count == 1)
    }

    @Test("작품 목록은 부분 수정이 아니라 편집 결과 전체가 전달된다")
    func sendsWholeNovelList() async throws {
        let mock = MockCollectionRepository()
        let useCase = DefaultUpdateCollectionUseCase(collectionRepository: mock)

        try await useCase.execute(
            id: CollectionID(31),
            draft: makeDraft(novelIDs: [NovelID(5), NovelID(9)])
        )

        #expect(mock.updatedRequests.last?.draft.novelIDs == [NovelID(5), NovelID(9)])
    }

    @Test("수정에 실패하면 에러를 그대로 전달한다")
    func updateFailure() async {
        let mock = MockCollectionRepository()
        mock.updateCollectionResult = .failure(.forbidden)
        let useCase = DefaultUpdateCollectionUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.forbidden) {
            try await useCase.execute(id: CollectionID(31), draft: makeDraft())
        }
    }
}

private extension UpdateCollectionUseCaseTests {
    func makeDraft(
        name: String = "취향 저격 로판",
        novelIDs: [NovelID] = [NovelID(1)]
    ) -> CollectionDraft {
        CollectionDraft(name: name, novelIDs: novelIDs)
    }
}
