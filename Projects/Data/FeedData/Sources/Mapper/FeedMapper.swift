//
//  FeedMapper.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import FeedDomain
import BaseDomain
import BaseData

enum FeedMapper {

    // MARK: - Genre

    static func genreString(from genre: NovelGenre) -> String {
        switch genre {
        case .romance:          return "romance"
        case .romanceFantasy:   return "romanceFantasy"
        case .fantasy:          return "fantasy"
        case .modernFantasy:    return "modernFantasy"
        case .wuxia:            return "wuxia"
        case .mystery:          return "mystery"
        case .drama:            return "drama"
        case .lightNovel:       return "lightNovel"
        case .BL:               return "BL"
        }
    }

    static func genre(from string: String) throws -> NovelGenre {
        switch string {
        case "romance":         return .romance
        case "romanceFantasy": return .romanceFantasy
        case "fantasy":         return .fantasy
        case "modernFantasy":  return .modernFantasy
        case "wuxia":           return .wuxia
        case "mystery":         return .mystery
        case "drama":           return .drama
        case "lightNovel":     return .lightNovel
        case "BL":              return .BL
        default:
            throw MappingError.invalidConversion(type: "NovelGenre", value: string)
        }
    }

    // MARK: - VisibilityType

    static func visibilityString(from type: VisibilityType) -> String {
        switch type {
        case .privateOnly:  return "PRIVATE"
        case .publicOnly:   return "PUBLIC"
        case .all:          return "ALL"
        }
    }

    // MARK: - Author

    static func author(userId: Int, nickname: String, avatarImage: String) -> Author {
        Author(
            userId: UserID(userId),
            nickname: nickname,
            // 아바타는 버킷 상대 경로로 올 수 있다 — 직조립하면 경로형에서 placeholder로 깨진다.
            profileImage: ImageURLResolver.resolve(from: avatarImage)
        )
    }

    // MARK: - ConnectedNovel (flat fields)

    static func connectedNovel(
        novelId: Int?,
        title: String?,
        genreName: String?,
        novelRating: Float?
    ) -> ConnectedNovel? {
        guard let novelId, let title, let genreName,
              let mappedGenre = try? genre(from: genreName) else { return nil }
        return ConnectedNovel(
            id: NovelID(novelId),
            title: title,
            genre: mappedGenre,
            rating: novelRating
        )
    }

    // MARK: - FeedDetail

    static func feedDetail(id: FeedID, from response: FeedDetailResponse) throws -> FeedDetail {
        let connectedNovelDetail: ConnectedNovelDetail?
        if let novelId = response.novelId,
           let title = response.title,
           let novelGenre = response.novelGenre,
           let mappedGenre = try? genre(from: novelGenre),
           let thumbnailImage = response.novelThumbnailImage,
           let description = response.novelDescription {
            let basicInfo = ConnectedNovel(
                id: NovelID(novelId),
                title: title,
                genre: mappedGenre,
                rating: response.novelRating
            )
            connectedNovelDetail = ConnectedNovelDetail(
                basicInfo: basicInfo,
                thumbnailImageURL: ImageURLResolver.resolve(from: thumbnailImage),
                descirption: description,
                feedWriterRating: response.feedWriterNovelRating
            )
        } else {
            connectedNovelDetail = nil
        }
        return FeedDetail(
            id: id,
            author: author(userId: response.userId,
                           nickname: response.nickname,
                           avatarImage: response.avatarImage),
            createdDate: response.createdDate,
            isModified: response.isModified,
            feedContent: response.feedContent,
            feedImageURLs: response.images.map { ImageURLResolver.resolve(from: $0) },
            connectedNovel: connectedNovelDetail,
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            isSpoiler: response.isSpoiler,
            isPublic: response.isPublic
        )
    }

    // MARK: - TotalFeed

    static func totalFeed(from response: TotalFeedResponse) -> TotalFeed {
        let novel = connectedNovel(
            novelId: response.novelId,
            title: response.title,
            genreName: response.genreName,
            novelRating: response.novelRating
        )
        return TotalFeed(
            feedId: FeedID(response.feedId),
            createdDate: response.createdDate,
            content: response.feedContent,
            author: author(userId: response.userId,
                           nickname: response.nickname,
                           avatarImage: response.avatarImage),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            isMyFeed: response.isMyFeed,
            thumbnailImageURL: response.thumbnailUrl.flatMap { ImageURLResolver.resolve(from: $0) },
            imageCount: response.imageCount
        )
    }

    // MARK: - TotalFeeds (getSosoFeeds, getMyFeeds)

    static func totalFeeds(from response: FeedListResponse) -> Paginated<TotalFeed> {
        let feeds = response.feeds.map { totalFeed(from: $0) }
        return Paginated(items: feeds, hasNext: response.isLoadable)
    }

    // MARK: - UserFeed

    // TODO: UserFeedResponse에 author 정보(nickname, avatarImage)가 없어 Author를 완전히 채울 수 없음
    // 응답에 isMyFeed도 없다 — 이 목록은 "한 사용자의 피드"라 소유 여부가 목록 단위로 같으므로
    // 호출 측(Repository)이 판단해 주입한다(내 피드 조회 = true, 타 유저 조회 = 저장된 userID 비교).
    static func userFeed(userID: UserID, isMyFeed: Bool, from response: UserFeedResponse) throws -> TotalFeed {
        let novel = connectedNovel(
            novelId: response.novelId,
            title: response.title,
            genreName: response.genre,
            novelRating: response.novelRating
        )
        return TotalFeed(
            feedId: FeedID(response.feedId),
            createdDate: response.createdDate,
            content: response.feedContent,
            author: Author(userId: userID,
                           nickname: "",
                           profileImage: nil),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            isMyFeed: isMyFeed,
            thumbnailImageURL: response.thumbnailUrl.flatMap { ImageURLResolver.resolve(from: $0) },
            imageCount: response.imageCount
        )
    }

    static func userFeeds(userID: UserID, isMyFeed: Bool, from response: UserFeedListResponse) throws -> Paginated<TotalFeed> {
        let feeds = try response.feeds.map { try userFeed(userID: userID, isMyFeed: isMyFeed, from: $0) }
        return Paginated(items: feeds, hasNext: response.isLoadable)
    }

    // MARK: - NovelFeed

    static func novelFeed(from response: NovelFeedResponse) throws -> TotalFeed {
        let novel = connectedNovel(
            novelId: response.novelId,
            title: response.title,
            genreName: response.genreName,
            novelRating: response.novelRating
        )
        return TotalFeed(
            feedId: FeedID(response.feedId),
            createdDate: response.createdDate,
            content: response.feedContent,
            author: author(userId: response.userId,
                           nickname: response.nickname,
                           avatarImage: response.avatarImage),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            isMyFeed: response.isMyFeed,
            thumbnailImageURL: response.thumbnailUrl.flatMap { ImageURLResolver.resolve(from: $0) },
            imageCount: response.imageCount
        )
    }

    static func novelFeeds(from response: NovelFeedListResponse) throws -> Paginated<TotalFeed> {
        let feeds = try response.feeds.map { try novelFeed(from: $0) }
        return Paginated(items: feeds, hasNext: response.isLoadable)
    }
}
