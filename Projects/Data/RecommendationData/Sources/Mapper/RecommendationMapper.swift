//
//  RecommendationMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

public enum RecommendationMapper {
    
    //MARK: - 오늘의 발견
    
    public static func todayDiscoveryNovels(from dto: TodayDiscoveryNovelsResponse) -> [TodayDiscovery] {
        return dto.popularNovels.map { todayDiscoveryNovel(from: $0) }
    }
    
    static func todayDiscoveryNovel(from dto: TodayDiscoveryNovelResponse) -> TodayDiscovery {
        let novelImageURL = URL(string: dto.novelImage)
        let isNovelIntroduction = (dto.nickname == nil || dto.avatarImage == nil)
        
        let content: TodayDiscovery.Content
        if isNovelIntroduction {
            content = .novel
        } else {
            let profileImageURL = URL(string: dto.avatarImage ?? "")
            let author = Author(nickname: dto.nickname ?? "웹소소",
                                profileImage: profileImageURL)
            content = .userComment(user: author)
        }
        
        return TodayDiscovery(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.title,
            novelThumbnailImage: novelImageURL,
            content: content,
            contentDescription: dto.feedContent
        )
    }
    
    //MARK: - 지금 뜨는 글
    
    public static func trendingFeeds(from dto: TrendingFeedsResponse) -> [TrendingFeed] {
        return dto.popularFeeds.map { trendingFeed(from: $0) }
    }
    
    static func trendingFeed(from dto: TrendingFeedResponse) -> TrendingFeed {
        return TrendingFeed(
            feedID: FeedID(dto.feedId),
            description: dto.feedContent,
            isSpoiler: dto.isSpoiler,
            likeCount: dto.likeCount,
            commentCount: dto.commentCount
        )
    }
    
    //MARK: - 관심글
    
    public static func interestFeeds(from dto: InterestFeedsResponse) -> InterestFeedState {
        switch InterestFeedsMessage(rawValue: dto.message) {
        case .noInterestNovels:
            return .noInterestSettings
        case .noAssociatedFeeds:
            return .noAssociatedFeeds
        default:
            return .feeds(dto.recommendFeeds.map { interestFeed(from: $0) })
        }
    }
    
    static func interestFeed(from dto: InterestFeedResponse) -> InterestFeed {
        let novelImageURL = URL(string: dto.novelImage)
        let authorProfileImageURL = URL(string: dto.avatarImage)
    
        return InterestFeed(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.novelTitle,
            novelThumbnailImage: novelImageURL,
            novelRating: dto.novelRating,
            novelRatingCount: dto.novelRatingCount,
            user: Author(nickname: dto.nickname,
                         profileImage: authorProfileImageURL),
            userComment: dto.feedContent
        )
    }
    
    //MARK: - 선호 장르 기반 추천 소설
    
    public static func preferenceGenreNovels(from dto: PreferenceGenreNovelsResponse) -> PreferenceGenreNovelState {
        if dto.tasteNovels.isEmpty {
            return .noGenreSettings
        }
        return .novels(dto.tasteNovels.map { preferenceGenreNovel(from: $0) })
    }
    
    static func preferenceGenreNovel(from dto: PreferenceGenreNovelResponse) -> PreferenceGenreNovel {
        let novelImageURL = URL(string: dto.novelImage)
        let novelAuthorArray: [String] = dto.author.components(separatedBy: ",")
 
        return PreferenceGenreNovel(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.title,
            novelThumbnailImage: novelImageURL,
            novelAuthors: novelAuthorArray,
            interestCount: dto.interestCount,
            ratingCount: dto.novelRatingCount,
            rating: dto.novelRating
        )
    }
    
    //MARK: - 소소픽
    
    public static func sosopickNovels(from dto: SosopickNovelsResponse) -> [SosoPick] {
        return dto.sosoPicks.map { sosopickNovel(from: $0) }
    }
    
    static func sosopickNovel(from dto: SosopickNovelResponse) -> SosoPick {
        let imageURL = URL(string: dto.novelImage)
        
        return SosoPick(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.title,
            novelThumbnailimage: imageURL
        )
    }
}
