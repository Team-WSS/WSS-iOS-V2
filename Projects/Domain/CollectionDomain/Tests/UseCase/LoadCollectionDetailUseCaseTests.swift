//
//  LoadCollectionDetailUseCaseTests.swift
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

@Suite("LoadCollectionDetailUseCase")
struct LoadCollectionDetailUseCaseTests {

    @Test("컬렉션 상세를 불러온다")
    func loadSuccess() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionDetailResult = .success(makeDetail(name: "취향 저격 로판"))
        let useCase = DefaultLoadCollectionDetailUseCase(collectionRepository: mock)

        let detail = try await useCase.execute(id: CollectionID(31), sortType: .recent)

        #expect(detail.name == "취향 저격 로판")
    }

    @Test("화면이 고른 정렬 기준이 그대로 전달된다")
    func passesSortType() async throws {
        let mock = MockCollectionRepository()
        mock.fetchCollectionDetailResult = .success(makeDetail())
        let useCase = DefaultLoadCollectionDetailUseCase(collectionRepository: mock)

        _ = try await useCase.execute(id: CollectionID(31), sortType: .old)

        #expect(mock.fetchedDetailRequests.last?.sortType == .old)
        #expect(mock.fetchedDetailRequests.last?.id == CollectionID(31))
    }

    @Test("없는 컬렉션을 조회하면 notFound를 전달한다")
    func loadNotFound() async {
        let mock = MockCollectionRepository()
        mock.fetchCollectionDetailResult = .failure(.notFound)
        let useCase = DefaultLoadCollectionDetailUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.notFound) {
            try await useCase.execute(id: CollectionID(99), sortType: .recent)
        }
    }

    @Test("남의 나만 보는 컬렉션을 조회하면 forbidden을 전달한다")
    func loadForbidden() async {
        let mock = MockCollectionRepository()
        mock.fetchCollectionDetailResult = .failure(.forbidden)
        let useCase = DefaultLoadCollectionDetailUseCase(collectionRepository: mock)

        await #expect(throws: RepositoryError.forbidden) {
            try await useCase.execute(id: CollectionID(31), sortType: .recent)
        }
    }
}

private extension LoadCollectionDetailUseCaseTests {
    func makeDetail(name: String = "컬렉션") -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(31),
            name: name,
            description: nil,
            owner: Author(userId: UserID(7), nickname: "웹소소", profileImage: nil),
            isMine: true,
            isPrivate: false,
            representativeNovelID: NovelID(1),
            novels: [CollectionNovel(id: NovelID(1), title: "작품", author: "작가", thumbnailImage: nil)],
            likeCount: 0,
            isLiked: false
        )
    }
}
