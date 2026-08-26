//
//  LoadCollectionPreviewsUseCaseTests.swift
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

@Suite("LoadCollectionPreviewsUseCase")
struct LoadCollectionPreviewsUseCaseTests {

    @Test("마이페이지 미리보기와 전체 컬렉션 수를 함께 불러온다")
    func loadSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionPreviewsResult = .success(([makePreview(), makePreview()], 7))
        let useCase = DefaultLoadCollectionPreviewsUseCase(collectionRepository: mock)

        let (previews, totalCount) = try await useCase.execute(userID: UserID(1), size: 3)

        #expect(previews.count == 2)
        #expect(totalCount == 7)
    }

    @Test("전체 개수는 이번에 받아온 미리보기 개수와 별개다")
    func totalCountIsIndependentFromPageSize() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionPreviewsResult = .success(([makePreview(), makePreview(), makePreview()], 21))
        let useCase = DefaultLoadCollectionPreviewsUseCase(collectionRepository: mock)

        let (previews, totalCount) = try await useCase.execute(userID: UserID(1), size: 3)

        #expect(previews.count == 3)
        #expect(totalCount == 21)
    }

    @Test("화면이 정한 조회 개수가 그대로 전달된다")
    func passesRequestedSize() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionPreviewsResult = .success(([], 0))
        let useCase = DefaultLoadCollectionPreviewsUseCase(collectionRepository: mock)

        _ = try await useCase.execute(userID: UserID(42), size: 3)

        #expect(mock.fetchedPreviewRequests.last?.size == 3)
        #expect(mock.fetchedPreviewRequests.last?.userID == UserID(42))
        #expect(mock.fetchedPreviewRequests.count == 1)
    }

    @Test("조회에 실패하면 에러를 그대로 전달한다")
    func loadFailure() async {
        let mock = MockCollectionRepository()
        mock.fetchCollectionPreviewsResult = .failure(.networkUnavailable)
        let useCase = DefaultLoadCollectionPreviewsUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.execute(userID: UserID(1), size: 3)
        }
    }
}

private extension LoadCollectionPreviewsUseCaseTests {
    func makePreview() -> CollectionPreview {
        CollectionPreview(
            id: CollectionID(1),
            name: "취향 저격 로판",
            representativeNovel: CollectionNovel(id: NovelID(1), title: "작품", author: "작가", thumbnailImage: nil)
        )
    }
}
