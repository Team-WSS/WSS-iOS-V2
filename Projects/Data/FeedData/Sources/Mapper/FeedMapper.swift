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

    /// 내 피드 공개범위 필터를 서버 쿼리 파라미터(isVisible/isUnVisible)로 변환한다.
    /// all은 둘 다 nil(필터 없음), publicOnly는 isVisible=true, privateOnly는 isUnVisible=true.
    /// (예전엔 Service가 문자열 "PUBLIC"/"PRIVATE"를 다시 Bool로 바꿨으나, 그 매핑을
    ///  Service 밖으로 걷어내 매퍼로 모았다 — Service는 순수 passthrough 유지.)
    static func visibilityFlags(from type: VisibilityType) -> (isVisible: Bool?, isUnVisible: Bool?) {
        switch type {
        case .publicOnly:   return (isVisible: true, isUnVisible: nil)
        case .privateOnly:  return (isVisible: nil, isUnVisible: true)
        case .all:          return (isVisible: nil, isUnVisible: nil)
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

    // UserFeedResponse에 author 정보(nickname, avatarImage)도 isMyFeed도 없다 — 이 목록은 "한 사용자의
    // 피드"라 author·소유 여부가 목록 단위로 동일하므로 호출 측(Repository)이 판단해 주입한다.
    static func userFeed(author: Author, isMyFeed: Bool, from response: UserFeedResponse) throws -> TotalFeed {
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
            author: author,
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

    static func userFeeds(author: Author, isMyFeed: Bool, from response: UserFeedListResponse) throws -> Paginated<TotalFeed> {
        let feeds = try response.feeds.map { try userFeed(author: author, isMyFeed: isMyFeed, from: $0) }
        // feedsCount는 페이지네이션 이전 전체 개수 — 내 피드 "n개의 기록" 표시에 로드된 배열 길이 대신 쓴다(V1 parity).
        return Paginated(items: feeds, hasNext: response.isLoadable, totalCount: response.feedsCount)
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
