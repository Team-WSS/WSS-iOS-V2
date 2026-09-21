//
//  LoadCollectionDetailUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadCollectionDetailUseCase: Sendable {
    /// 컬렉션 상세를 가져온다. 작품은 페이지네이션 없이 전부 온다.
    /// - Parameter sortType: 화면의 "등록 최신순 / 등록 오래된순" 토글. 정렬을 바꾸면 다시 호출한다.
    func execute(id: CollectionID, sortType: SortType) async throws(RepositoryError) -> CollectionDetail
}

public final class DefaultLoadCollectionDetailUseCase: LoadCollectionDetailUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(id: CollectionID, sortType: SortType) async throws(RepositoryError) -> CollectionDetail {
        try await collectionRepository.fetchCollectionDetail(id: id, sortType: sortType)
    }
}
