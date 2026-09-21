//
//  CollectionRepository.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol CollectionRepository: Sendable {

    /// 마이페이지 컬렉션 섹션용 미리보기 목록.
    ///
    /// 전용 API가 아니라 사용자별 컬렉션 목록을 앞에서 `size`개만 잘라 쓴다(현재 화면은 3개).
    /// 무한 스크롤이 없어 커서를 쓰지 않으므로 `CursorPaginated` 대신 배열로 돌려준다.
    /// - Returns: (미리보기 목록, 조회자가 볼 수 있는 전체 컬렉션 수)
    func fetchCollectionPreviews(
        userID: UserID,
        size: Int
    ) async throws(RepositoryError) -> ([CollectionPreview], Int)

    /// 사용자별 컬렉션 목록. 최초 생성 시점 최신순.
    ///
    /// 본인 목록에는 나만 보는 컬렉션이 함께 오고, 다른 사용자 목록에는 공개 컬렉션만 온다
    /// — 화면에서 걸러낼 필요가 없다.
    /// - Parameter cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    /// - Returns: (커서 페이지, 조회자가 볼 수 있는 전체 컬렉션 수)
    func fetchCollections(
        userID: UserID,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int)

    /// 좋아요한 컬렉션 목록. 좋아요한 시점 최신순.
    /// - Returns: (커서 페이지, 전체 좋아요한 컬렉션 수)
    func fetchLikedCollections(
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int)

    /// 컬렉션 상세. 작품은 페이지네이션 없이 전부 내려온다.
    /// - Parameter sortType: 작품 정렬. `.recent`는 저장된 표시 순서 그대로, `.old`는 그 역순.
    func fetchCollectionDetail(
        id: CollectionID,
        sortType: SortType
    ) async throws(RepositoryError) -> CollectionDetail

    /// - Returns: 생성된 컬렉션 ID
    func createCollection(_ draft: CollectionDraft) async throws(RepositoryError) -> CollectionID

    func updateCollection(id: CollectionID, draft: CollectionDraft) async throws(RepositoryError)

    func deleteCollection(id: CollectionID) async throws(RepositoryError)

    /// 좋아요 등록·취소는 멱등이다 — 이미 그 상태여도 서버가 에러를 내지 않는다.
    /// 소유자도 자기 컬렉션에 좋아요를 누를 수 있다.
    func likeCollection(id: CollectionID) async throws(RepositoryError)
    func unlikeCollection(id: CollectionID) async throws(RepositoryError)
}
