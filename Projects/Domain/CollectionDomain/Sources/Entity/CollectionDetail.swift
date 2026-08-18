//
//  CollectionDetail.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 컬렉션 상세 화면이 쓰는 컬렉션 전체. 목록 카드와 달리 작품이 페이지네이션 없이 전부 내려온다.
public struct CollectionDetail {

    public let id: CollectionID
    public let name: String

    /// 없으면 nil.
    public let description: String?

    public let owner: Author

    /// 조회자가 소유자인지 여부. 비로그인 조회는 항상 false다.
    /// 더보기(수정·삭제) 노출 여부가 이 값에 달려 있다.
    public let isMine: Bool

    /// "나만 보는 컬렉션" 여부. 서버 `isPublic`의 반대값.
    /// 나만 보는 컬렉션은 공유하기 대신 비활성 배지가 나가고, 소유자에게만 보인다.
    public let isPrivate: Bool

    /// 대표 작품. 표지로 쓰이며 `novels`에 반드시 포함된다(서버가 생성·수정 시 그렇게 강제한다).
    public let representativeNovelID: NovelID

    /// 컬렉션에 든 전체 작품. 요청한 정렬 기준으로 정렬돼 오고 페이지네이션이 없다.
    public let novels: [CollectionNovel]

    /// 컬렉션이 받은 전체 좋아요 수. 조회자의 좋아요 여부와 무관하며 비공개로 바뀌어도 유지된다.
    public private(set) var likeCount: Int

    /// 조회자가 좋아요를 눌렀는지 여부. 비로그인 조회는 항상 false다.
    /// 소유자도 자기 컬렉션에 좋아요를 누를 수 있다.
    public private(set) var isLiked: Bool

    public var novelCount: Int { novels.count }

    public init(
        id: CollectionID,
        name: String,
        description: String?,
        owner: Author,
        isMine: Bool,
        isPrivate: Bool,
        representativeNovelID: NovelID,
        novels: [CollectionNovel],
        likeCount: Int,
        isLiked: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.owner = owner
        self.isMine = isMine
        self.isPrivate = isPrivate
        self.representativeNovelID = representativeNovelID
        self.novels = novels
        self.likeCount = likeCount
        self.isLiked = isLiked
    }

    // MARK: - Policy

    public mutating func markAsLiked() {
        guard isLiked == false else { return }
        isLiked = true
        likeCount += 1
    }

    public mutating func unmarkAsLiked() {
        guard isLiked == true else { return }
        isLiked = false
        likeCount = max(0, likeCount - 1)
    }

    public mutating func toggleLike() {
        if isLiked {
            unmarkAsLiked()
        } else {
            markAsLiked()
        }
    }
}
