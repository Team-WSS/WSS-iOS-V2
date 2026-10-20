//
//  CollectionMapper.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseData
import BaseDomain
import CollectionDomain

enum CollectionMapper {

    // MARK: - 목록

    /// 마이페이지 섹션용. 같은 응답에서 대표 작품만 뽑아 쓴다.
    /// - Returns: (미리보기 목록, 전체 컬렉션 수)
    public static func collectionPreviews(from dto: CollectionsResponse) -> ([CollectionPreview], Int) {
        let previews = dto.collections.map {
            CollectionPreview(
                id: CollectionID($0.collectionId),
                name: $0.collectionName,
                representativeNovel: collectionNovel(from: $0.representativeNovel)
            )
        }
        return (previews, dto.collectionsCount)
    }

    /// 사용자별·좋아요한 컬렉션 목록용. 서버가 소유자를 주지 않아 `owner`는 nil이다.
    /// - Parameters:
    ///   - ownerID: 목록 전체의 소유자. 사용자별 목록은 요청한 사용자, 좋아요 목록은 알 수 없어 nil.
    ///   - myID: 로그인 사용자. 비로그인이면 nil.
    /// - Returns: (커서 페이지, 전체 컬렉션 수)
    public static func collectionCards(
        from dto: CollectionsResponse,
        ownerID: UserID?,
        myID: UserID?
    ) -> (CursorPaginated<CollectionCard>, Int) {
        // 소유자를 모르면(좋아요 목록) 내 컬렉션이어도 false가 된다.
        let isMine = ownerID != nil && ownerID == myID
        let page = CursorPaginated(
            items: dto.collections.map {
                CollectionCard(
                    id: CollectionID($0.collectionId),
                    name: $0.collectionName,
                    description: $0.collectionDescription,
                    novelCount: $0.novelCount,
                    // 서버는 "공개인가"를, 도메인·화면은 "나만 보는가"를 말한다. 뒤집기는 여기서만 일어난다.
                    // 남의 나만 보는 컬렉션은 서버가 내려주지 않아 소유자 여부와 상관없이 그대로 따른다.
                    isPrivate: $0.isPublic == false,
                    recentNovels: $0.recentNovels.map(collectionNovel(from:)),
                    owner: nil,
                    isMine: isMine
                )
            },
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor
        )
        return (page, dto.collectionsCount)
    }

    /// 홈 컬렉션 섹션·전체 컬렉션뷰용. 공개 컬렉션만 내려오므로 `isPrivate`은 항상 false다.
    /// - Parameter myID: 로그인 사용자. 비로그인이면 nil.
    public static func publicCollectionCards(
        from dto: PublicCollectionsResponse,
        myID: UserID?
    ) -> CursorPaginated<CollectionCard> {
        CursorPaginated(
            items: dto.collections.map {
                let owner = author(from: $0.owner)
                return CollectionCard(
                    id: CollectionID($0.collectionId),
                    name: $0.collectionName,
                    description: $0.collectionDescription,
                    novelCount: $0.novelCount,
                    isPrivate: false,
                    recentNovels: $0.recentNovels.map(collectionNovel(from:)),
                    owner: owner,
                    isMine: myID != nil && owner.userId == myID
                )
            },
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor
        )
    }

    // MARK: - 상세

    public static func collectionDetail(from dto: CollectionDetailResponse) -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(dto.collectionId),
            name: dto.collectionName,
            description: dto.collectionDescription,
            owner: author(from: dto.owner),
            isMine: dto.isMyCollection,
            isPrivate: dto.isPublic == false,
            representativeNovelID: NovelID(dto.representativeNovelId),
            novels: dto.novels.map(collectionNovel(from:)),
            likeCount: dto.likeCount,
            isLiked: dto.isLiked
        )
    }

    // MARK: - 생성·수정 요청

    /// 초안을 서버 요청 바디로 바꾼다.
    ///
    /// 대표 작품은 서버 필수값이라 초안이 아직 고르지 않았으면 표시 순서 첫 작품으로 대신한다
    /// (`effectiveRepresentativeNovelID`). 작품이 하나도 없으면 대신할 것이 없어 실패한다 —
    /// 화면이 완료 버튼을 잠가 막지만, 계약을 어긴 요청이 서버까지 나가지 않도록 여기서도 끊는다.
    public static func submitRequest(from draft: CollectionDraft) throws -> SubmitCollectionRequest {
        guard let representativeNovelID = draft.effectiveRepresentativeNovelID else {
            throw MappingError.invalidPayload(reason: "컬렉션에는 작품이 최소 하나 있어야 한다")
        }

        return SubmitCollectionRequest(
            name: draft.name,
            // 설명은 선택 항목이라 비어 있으면 보내지 않는다.
            description: draft.description.isEmpty ? nil : draft.description,
            isPublic: draft.isPrivate == false,
            novelIds: draft.novelIDs.map(\.value),
            representativeNovelId: representativeNovelID.value
        )
    }

    // MARK: - 공통

    private static func author(from dto: CollectionOwnerResponse) -> Author {
        Author(
            userId: UserID(dto.userId),
            nickname: dto.nickname,
            profileImage: dto.avatarImage.flatMap { ImageURLResolver.resolve(from: $0) }
        )
    }

    private static func collectionNovel(from dto: CollectionNovelResponse) -> CollectionNovel {
        CollectionNovel(
            id: NovelID(dto.novelId),
            title: dto.title,
            author: dto.author,
            thumbnailImage: dto.novelImage.flatMap { ImageURLResolver.resolve(from: $0) }
        )
    }
}
