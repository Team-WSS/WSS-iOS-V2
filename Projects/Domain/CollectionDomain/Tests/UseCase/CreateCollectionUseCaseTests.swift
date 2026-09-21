//
//  CreateCollectionUseCaseTests.swift
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

@Suite("CreateCollectionUseCase")
struct CreateCollectionUseCaseTests {

    @Test("컬렉션을 만들면 생성된 컬렉션 ID를 돌려준다")
    func createSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.createCollectionResult = .success(CollectionID(12))
        let useCase = DefaultCreateCollectionUseCase(collectionRepository: mock)

        let id = try await useCase.execute(makeDraft())

        #expect(id == CollectionID(12))
        #expect(mock.createdDrafts.count == 1)
    }

    @Test("작품의 표시 순서가 초안 그대로 전달된다")
    func preservesNovelOrder() async throws {
        let mock = MockCollectionRepository()
        mock.createCollectionResult = .success(CollectionID(1))
        let useCase = DefaultCreateCollectionUseCase(collectionRepository: mock)

        _ = try await useCase.execute(makeDraft(novelIDs: [NovelID(9), NovelID(5), NovelID(3)]))

        #expect(mock.createdDrafts.last?.novelIDs == [NovelID(9), NovelID(5), NovelID(3)])
    }

    @Test("나만 보는 설정이 초안 그대로 전달된다")
    func passesPrivacy() async throws {
        let mock = MockCollectionRepository()
        mock.createCollectionResult = .success(CollectionID(1))
        let useCase = DefaultCreateCollectionUseCase(collectionRepository: mock)

        _ = try await useCase.execute(makeDraft(isPrivate: true))

        #expect(mock.createdDrafts.last?.isPrivate == true)
    }

    @Test("생성에 실패하면 에러를 그대로 전달한다")
    func createFailure() async {
        let mock = MockCollectionRepository()
        mock.createCollectionResult = .failure(.invalidData)
        let useCase = DefaultCreateCollectionUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.invalidData) {
            try await useCase.execute(makeDraft())
        }
    }
}

private extension CreateCollectionUseCaseTests {
    func makeDraft(
        isPrivate: Bool = false,
        novelIDs: [NovelID] = [NovelID(1)]
    ) -> CollectionDraft {
        CollectionDraft(
            name: "취향 저격 로판",
            description: "여주가 강한 로맨스 판타지",
            isPrivate: isPrivate,
            novelIDs: novelIDs
        )
    }
}
