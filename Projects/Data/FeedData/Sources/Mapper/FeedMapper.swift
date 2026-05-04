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
            profileImage: URL(string: avatarImage)
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
                thumbnailImage: ImageWrapper(identifier: thumbnailImage),
                descirption: description,
                feedWriterRating: response.feedWriterNovelRating
            )
        } else {
            connectedNovelDetail = nil
        }
        return FeedDetail(
            id: id,
            author: author(userId: response.userId, nickname: response.nickname, avatarImage: response.avatarImage),
            createdDate: response.createdDate,
            isModified: response.isModified,
            feedContent: response.feedContent,
            feedImageURLs: response.images.map { Optional(ImageWrapper(identifier: $0)) },
            connectedNovel: connectedNovelDetail,
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount
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
            author: author(userId: response.userId, nickname: response.nickname, avatarImage: response.avatarImage),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            thumbnailImageURL: response.thumbnailUrl.map { ImageWrapper(identifier: $0) },
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
    static func userFeed(userID: UserID, from response: UserFeedResponse) throws -> TotalFeed {
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
            author: Author(userId: userID, nickname: "", profileImage: nil),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            thumbnailImageURL: response.thumbnailUrl.map { ImageWrapper(identifier: $0) },
            imageCount: response.imageCount
        )
    }

    static func userFeeds(userID: UserID, from response: UserFeedListResponse) throws -> Paginated<TotalFeed> {
        let feeds = try response.feeds.map { try userFeed(userID: userID, from: $0) }
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
            author: author(userId: response.userId, nickname: response.nickname, avatarImage: response.avatarImage),
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            commentCount: response.commentCount,
            connectedNovel: novel,
            isSpoiler: response.isSpoiler,
            isModified: response.isModified,
            isPublic: response.isPublic,
            thumbnailImageURL: response.thumbnailUrl.map { ImageWrapper(identifier: $0) },
            imageCount: response.imageCount
        )
    }

    static func novelFeeds(from response: NovelFeedListResponse) throws -> Paginated<TotalFeed> {
        let feeds = try response.feeds.map { try novelFeed(from: $0) }
        return Paginated(items: feeds, hasNext: response.isLoadable)
    }
}
