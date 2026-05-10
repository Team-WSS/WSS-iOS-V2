//
//  NovelMapper.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain

public enum NovelMapper {
    
    // MARK: - Mapping Error
    
    enum MappingError: Error {
        case invalidReadingStatus(String)
        case invalidAttractivePoint(String)
        case invalidDateFormat(String)
        case invalidNovelGenre(String)
        case invalidPlatformUrl(String)
    }
}

// MARK: - DTO -> Entity

extension NovelMapper {
    
    // MARK: - 서재 - 소설
    
    public static func libraryNovel(from dto: UserLibraryNovelResponse) throws -> LibraryNovel {
        let novelImageURL = URL(string: dto.novelImage)
        
        var userReview: UserNovelReview?
        if let readStatusString = dto.readStatus {
            let readingStatus = try mapReadingStatus(from: readStatusString)
            let attractivePoints = try dto.attractivePoints.map { try mapAttractivePoint(from: $0) }
            let period = try mapReadingPeriod(startDate: dto.startDate ?? "",
                                              endDate: dto.endDate ?? "")
            let rating = try? Rating(Double(dto.userNovelRating))
            
            userReview = UserNovelReview(
                readingStatus: readingStatus,
                rating: rating,
                attractivePoint: attractivePoints,
                period: period,
                keywords: []
            )
        }
        
        return LibraryNovel(
            id: NovelID(dto.novelId),
            title: dto.title,
            thumbnailImage: novelImageURL,
            rating: dto.novelRating,
            isInterested: dto.isInterest,
            userReview: userReview,
            writtenFeeds: dto.myFeeds
        )
    }
    
    public static func libraryNovels(from dto: UserLibraryNovelsResponse) throws -> LibraryNovels {
        return LibraryNovels(
            totalCount: dto.userNovelCount,
            novels: Paginated(items: try dto.userNovels.map { try libraryNovel(from: $0) },
                              hasNext: dto.isLoadable)
        )
    }
    
    // MARK: - 작품 상세 정보
    
    public static func novelInformation(id: NovelID,
                                              from basicDTO: NovelBasicResponse,
                                              from detailDTO: NovelInfoResponse) throws -> NovelInformation {
        let authors = basicDTO.author
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let novel = Novel(
            //TODO: - id값을 어떻게 처리하면 좋을지 고민
            id: id,
            thumbnailImage: URL(string: basicDTO.novelGenreImage),
            title: basicDTO.novelTitle,
            authors: authors,
            interestCount: basicDTO.interestCount,
            rating: basicDTO.novelRating,
            ratingCount: basicDTO.novelRatingCount
        )
        
        var userReview: UserNovelReview?
        if let readStatusString = basicDTO.readStatus {
            let readingStatus = try mapReadingStatus(from: readStatusString)
            let attractivePoints = try detailDTO.attractivePoints.map { try mapAttractivePoint(from: $0) }
            let period = try mapReadingPeriod(startDate: basicDTO.startDate ?? "",
                                              endDate: basicDTO.endDate ?? "")
            let rating = try? Rating(Double(basicDTO.userNovelRating))
            
            userReview = UserNovelReview(
                readingStatus: readingStatus,
                rating: rating,
                attractivePoint: attractivePoints,
                period: period,
                keywords: []
            )
        }
        
        let platforms = try detailDTO.platforms.map { try mapPlatform(from: $0) }
        
        return NovelInformation(
            novel: novel,
            feedCount: basicDTO.feedCount,
            genres: try basicDTO.novelGenres
                .components(separatedBy: ",")
                .map { try mapNovelGenre(from: $0.trimmingCharacters(in: .whitespaces)) },
            publicationStatus: mapPublicationStatus(from: basicDTO.isNovelCompleted),
            userReview: userReview,
            description: detailDTO.novelDescription,
            platforms: platforms,
            attractivePoints: try detailDTO.attractivePoints.map { try mapAttractivePoint(from: $0) },
            // TODO: - Keyword 매핑 추가 필요 (KeywordID 문제 해결 후)
            // 앱 시작할 떄 변수에 키워드를 저장하고, Data모듈에서 매핑하는 방식으로 합니다.
            keywords: [:],
            readingStatusCount: [
                .watching: detailDTO.watchingCount,
                .watched: detailDTO.watchedCount,
                .quit: detailDTO.quitCount
            ]
        )
    }
    
    // MARK: - 유저의 등록 작품 상태
    
    public static func userRegisteredNovelStats(from dto: UserRegisteredNovelStatesResponse) -> RegisteredNovelStats {
        return RegisteredNovelStats(
            interest: dto.interestNovelCount,
            watching: dto.watchingNovelCount,
            watched: dto.watchedNovelCount,
            quit: dto.quitNovelCount
        )
    }
    
    //MARK: - 일반 검색 작품
    
    public static func searchNovels(from dto: SearchNovelsResponse) -> (Paginated<Novel>, Int) {
        let novels = dto.novels.map { searchNovel(from: $0) }
        let paginated = Paginated(items: novels, hasNext: dto.isLoadable)
        return (paginated, dto.resultCount)
    }
    
    public static func searchNovel(from dto: SearchNovelResponse) -> Novel {
        let thumbnailImageURL = URL(string: dto.novelImage)
        let authors = dto.author
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        return Novel(
            id: NovelID(dto.novelId),
            thumbnailImage: thumbnailImageURL,
            title: dto.title,
            authors: authors,
            interestCount: dto.interestCount,
            rating: dto.novelRating,
            ratingCount: dto.novelRatingCount
        )
    }
}

//MARK: - Entity -> DTO

extension NovelMapper {

    // MARK: - 서재 조회 Query

    static func myLibraryQuery(from filter: MyLibraryFilter) -> UserLibraryQuery {
        UserLibraryQuery(
            lastUserNovelId: 0,
            size: 20,
            sortCriteria: filter.sortType.rawValue,
            isInterest: filter.isInterest,
            readStatuses: filter.readingStatus.map { mapReadingStatusString(from: $0) },
            attractivePoints: filter.attractivePoint.map { mapAttractivePointString(from: $0) },
            novelRating: filter.ratingThreshold?.rawValue ?? 0,
            query: "",
            updatedSince: ""
        )
    }

    static func userLibraryQuery(from filter: LibraryFilter) -> UserLibraryQuery {
        UserLibraryQuery(
            lastUserNovelId: 0,
            size: 20,
            sortCriteria: filter.sortType.rawValue,
            isInterest: false,
            readStatuses: [],
            attractivePoints: [],
            novelRating: 0,
            query: "",
            updatedSince: ""
        )
    }

    // MARK: - 상세 탐색 Query

    static func detailSearchQuery(from filter: SearchFilter) -> DetailSearchQuery {
        DetailSearchQuery(
            genres: filter.genres.map { mapNovelGenreString(from: $0) },
            isCompleted: filter.publicationStatus == .completed,
            novelRating: filter.ratingThreshold?.rawValue ?? 0,
            keywordIds: filter.keywords.map { $0.id.value },
            page: 0,
            size: 20
        )
    }
}

// MARK: - Mapping Helpers

extension NovelMapper {
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
    
    private static func mapReadingStatus(from value: String) throws -> ReadingStatus {
        guard let status = ReadingStatus(rawValue: value.lowercased()) else {
            throw MappingError.invalidReadingStatus(value)
        }
        return status
    }
    
    private static func mapReadingStatusString(from value: ReadingStatus) -> String {
        switch value {
        case .watching: return "WATCHING"
        case .watched: return "WATCHED"
        case .quit: return "QUIT"
        }
    }
    
    private static func mapAttractivePoint(from value: String) throws -> AttractivePoint {
        switch value {
        case "worldview": return .worldview
        case "material": return .material
        case "character": return .character
        case "relationship": return .relationship
        case "vibe": return .vibe
        case "writingskill": return .writingSkill
        default: throw MappingError.invalidAttractivePoint(value)
        }
    }
    
    private static func mapAttractivePointString(from value: AttractivePoint) -> String {
        switch value {
        case .worldview: return "worldview"
        case .material: return "material"
        case .character: return "character"
        case .relationship: return "relationship"
        case .vibe: return "vibe"
        case .writingSkill: return "writingskill"
        }
    }
    
    private static func mapReadingPeriod(startDate: String, endDate: String) throws -> ReadingPeriod? {
        guard !startDate.isEmpty || !endDate.isEmpty else {
            return nil
        }
        
        var start: Date?
        if !startDate.isEmpty {
            guard let date = dateFormatter.date(from: startDate) else {
                throw MappingError.invalidDateFormat(startDate)
            }
            start = date
        }
        
        var end: Date?
        if !endDate.isEmpty {
            guard let date = dateFormatter.date(from: endDate) else {
                throw MappingError.invalidDateFormat(endDate)
            }
            end = date
        }
        
        return try ReadingPeriod(start: start, end: end)
    }
    
    static func mapNovelGenreString(from genre: NovelGenre) -> String {
        switch genre {
        case .lightNovel:      return "lightNovel"
        case .wuxia:           return "wuxia"
        case .fantasy:         return "fantasy"
        case .romance:         return "romance"
        case .BL:              return "BL"
        case .romanceFantasy:  return "romanceFantasy"
        case .modernFantasy:   return "modernFantasy"
        case .drama:           return "drama"
        case .mystery:         return "mystery"
        }
    }

    private static func mapNovelGenre(from value: String) throws -> NovelGenre {
        switch value {
        case "lightNovel":      return .lightNovel
        case "wuxia":           return .wuxia
        case "fantasy":         return .fantasy
        case "romance":         return .romance
        case "BL":              return .BL
        case "romanceFantasy":  return .romanceFantasy
        case "modernFantasy":   return .modernFantasy
        case "drama":           return .drama
        case "mystery":         return .mystery
        default:                throw MappingError.invalidNovelGenre(value)
        }
    }
    
    private static func mapPublicationStatus(from isCompleted: Bool) -> NovelPublicationStatus {
        isCompleted ? .completed : .onGoing
    }
    
    private static func mapPlatform(from dto: NovelPlatformResponse) throws -> NovelPlatform {
        guard let url = URL(string: dto.platformUrl) else {
            throw MappingError.invalidPlatformUrl(dto.platformUrl)
        }
        return NovelPlatform(
            name: dto.platformName,
            image: URL(string: dto.platformImage),
            url: url
        )
    }
}
