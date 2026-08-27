//
//  LoadCollectionPreviewsUseCase.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadCollectionPreviewsUseCase: Sendable {
    /// 마이페이지 컬렉션 섹션에 보여줄 미리보기를 가져온다.
    ///
    /// 전용 API가 없어 사용자별 컬렉션 목록을 앞에서 `size`개만 잘라 쓴다.
    /// `size`를 상수로 박지 않는 이유는 화면이 몇 개를 보여줄지 정하기 때문이다(서재도 같은 이유로 관통시켰다).
    /// - Returns: (미리보기 목록, 전체 컬렉션 수 — 섹션 상단의 "컬렉션 N개")
    func execute(userID: UserID, size: Int) async throws(RepositoryError) -> ([CollectionPreview], Int)
}

public final class DefaultLoadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase {

    private let collectionRepository: CollectionRepository

    public init(collectionRepository: CollectionRepository) {
        self.collectionRepository = collectionRepository
    }

    public func execute(userID: UserID, size: Int) async throws(RepositoryError) -> ([CollectionPreview], Int) {
        try await collectionRepository.fetchCollectionPreviews(userID: userID, size: size)
    }
}
