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
import BaseData

public enum RecommendationMapper {
    
    //MARK: - 오늘의 발견
    
    public static func todayDiscoveryNovels(from dto: TodayDiscoveryNovelsResponse) throws -> [TodayDiscovery] {
        return try dto.popularNovels.map { try todayDiscoveryNovel(from: $0) }
    }

    static func todayDiscoveryNovel(from dto: TodayDiscoveryNovelResponse) throws -> TodayDiscovery {
        let novelImageURL = ImageURLResolver.resolve(from: dto.novelImage)

        // 카드 본문의 출처가 형태마다 다르다 — 작품 소개 카드는 novelDescription을,
        // 유저 한마디 카드는 그 유저가 쓴 feedContent를 본문으로 쓴다.
        // ⚠️ 형태 판정에 **`feedContent`를 끌어들이지 말 것** — 서버가 소개 카드의 feedContent에도
        // 같은 소개글을 넣어 보내는 경우가 있어(#179 실측) 멀쩡한 소개 카드가 한마디로 뒤집힌다.
        let content: TodayDiscovery.Content
        let contentDescription: String

        switch (dto.nickname, dto.avatarImage) {
        case (nil, nil):
            content = .novel
            contentDescription = dto.novelDescription

        case let (nickname?, avatarImage?):
            // 유저 한마디인데 본문이 없으면 **말풍선만 있고 내용이 빈 카드**가 그려진다.
            // 폴백으로 덮어 조용히 통과시키지 않고 매핑 실패로 돌린다(→ `.invalidData`).
            guard let feedContent = dto.feedContent else {
                throw MappingError.invalidPayload(
                    reason: "Missing feedContent for user comment card: novelId \(dto.novelId)"
                )
            }

            let author = Author(nickname: nickname,
                                profileImage: ImageURLResolver.resolve(from: avatarImage))
            content = .userComment(user: author)
            contentDescription = feedContent

        default:
            // 닉네임·아바타는 유저 한마디 카드에서 **함께** 채워지거나 함께 null이다(다른 응답들이
            // avatarImage를 필수로 받는 것과 같은 계약). 한쪽만 온 건 서버 이상이므로, 작품 소개
            // 카드로 눙쳐 한마디를 조용히 잃지 말고 드러낸다.
            throw MappingError.invalidPayload(
                reason: "Partial user info in today discovery: novelId \(dto.novelId)"
            )
        }

        return TodayDiscovery(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.title,
            novelThumbnailImage: novelImageURL,
            novelAuthor: dto.author,
            novelGenre: try novelGenre(from: dto.genreName),
            publicationStatus: dto.isNovelCompleted ? .completed : .onGoing,
            keywords: dto.keywords,
            content: content,
            contentDescription: contentDescription
        )
    }

    //MARK: - 지금 뜨는 글

    public static func trendingFeeds(from dto: TrendingFeedsResponse) throws -> [TrendingFeed] {
        return try dto.popularFeeds.map { try trendingFeed(from: $0) }
    }

    static func trendingFeed(from dto: TrendingFeedResponse) throws -> TrendingFeed {
        return TrendingFeed(
            feedID: FeedID(dto.feedId),
            novelTitle: dto.novelTitle,
            novelThumbnailImage: ImageURLResolver.resolve(from: dto.novelImage),
            novelGenre: try novelGenre(from: dto.novelGenre),
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
        let novelImageURL = ImageURLResolver.resolve(from: dto.novelImage)
        let authorProfileImageURL = ImageURLResolver.resolve(from: dto.avatarImage)
    
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
        let novelImageURL = ImageURLResolver.resolve(from: dto.novelImage)
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
        let imageURL = ImageURLResolver.resolve(from: dto.novelImage)

        return SosoPick(
            novelID: NovelID(dto.novelId),
            novelTitle: dto.title,
            novelThumbnailimage: imageURL
        )
    }

    //MARK: - 공통

    /// 홈 응답의 장르는 한글이 아니라 **영문 케이스명**으로 온다(`romanceFantasy`·`BL` 등).
    /// 한글로 오는 작품 상세(`NovelMapper`)와 값이 달라 그쪽 매핑을 재사용할 수 없다.
    static func novelGenre(from text: String) throws -> NovelGenre {
        switch text {
        case "lightNovel":      return .lightNovel
        case "wuxia":           return .wuxia
        case "fantasy":         return .fantasy
        case "romance":         return .romance
        case "BL":              return .BL
        case "romanceFantasy":  return .romanceFantasy
        case "modernFantasy":   return .modernFantasy
        case "drama":           return .drama
        case "mystery":         return .mystery
        default:
            throw MappingError.invalidConversion(type: "NovelGenre", value: text)
        }
    }
}
