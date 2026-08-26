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

public enum CollectionMapper {

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

    /// 컬렉션 리스트·좋아요한 목록용. 같은 응답에서 미리보기 썸네일 줄을 쓴다.
    /// - Returns: (커서 페이지, 전체 컬렉션 수)
    public static func collectionCards(from dto: CollectionsResponse) -> (CursorPaginated<CollectionCard>, Int) {
        let page = CursorPaginated(
            items: dto.collections.map(collectionCard(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor
        )
        return (page, dto.collectionsCount)
    }

    private static func collectionCard(from dto: CollectionCardResponse) -> CollectionCard {
        CollectionCard(
            id: CollectionID(dto.collectionId),
            name: dto.collectionName,
            description: dto.collectionDescription,
            novelCount: dto.novelCount,
            // 서버는 "공개인가"를, 도메인·화면은 "나만 보는가"를 말한다. 뒤집기는 여기 한 곳뿐이다.
            isPrivate: dto.isPublic == false,
            recentNovels: dto.recentNovels.map(collectionNovel(from:))
        )
    }

    // MARK: - 상세

    public static func collectionDetail(from dto: CollectionDetailResponse) -> CollectionDetail {
        CollectionDetail(
            id: CollectionID(dto.collectionId),
            name: dto.collectionName,
            description: dto.collectionDescription,
            owner: Author(
                userId: UserID(dto.owner.userId),
                nickname: dto.owner.nickname,
                profileImage: dto.owner.avatarImage.flatMap { ImageURLResolver.resolve(from: $0) }
            ),
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

    private static func collectionNovel(from dto: CollectionNovelResponse) -> CollectionNovel {
        CollectionNovel(
            id: NovelID(dto.novelId),
            title: dto.title,
            author: dto.author,
            thumbnailImage: dto.novelImage.flatMap { ImageURLResolver.resolve(from: $0) }
        )
    }
}
