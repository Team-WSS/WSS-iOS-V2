//
//  NovelMapper.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import NovelDomain
import BaseData

public enum NovelMapper {
    
    // MARK: - Mapping Error
    
    enum MappingError: Error {
        case invalidReadingStatus(String)
        case invalidAttractivePoint(String)
        case invalidDateFormat(String)
        case invalidReadingPeriod(start: String, end: String)
        case invalidNovelGenre(String)
        case invalidPlatformUrl(String)
    }
}

// MARK: - DTO -> Entity

extension NovelMapper {
    
    // MARK: - 서재 - 소설
    
    public static func libraryNovel(
        from dto: UserLibraryNovelResponse,
        cachedKeywords: [Keyword] = []
    ) throws -> LibraryNovel {
        let novelImageURL = ImageURLResolver.resolve(from: dto.novelImage)
        
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
                keywords: mapKeywords(from: dto.keywords, cachedKeywords: cachedKeywords)
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

    public static func libraryNovelsV2(
        from dto: UserLibraryNovelsV2Response,
        cachedKeywords: [Keyword]
    ) throws -> (CursorPaginated<LibraryNovel>, Int) {
        let page = CursorPaginated(
            items: try dto.userNovels.map {
                try libraryNovel(from: $0, cachedKeywords: cachedKeywords)
            },
            hasNext: dto.isLoadable,
            nextCursor: dto.nextCursor
        )
        return (page, dto.userNovelCount)
    }

    // MARK: - 서재 - 등록 키워드

    public static func libraryKeywords(from dto: LibraryKeywordsResponse) -> [Keyword] {
        dto.keywords.map { Keyword(id: KeywordID($0.keywordId), name: $0.keywordName) }
    }
    
    // MARK: - 작품 상세 정보
    
    public static func novelInformation(id: NovelID,
                                        from basicDTO: NovelBasicResponse,
                                        from detailDTO: NovelInfoResponse,
                                        cachedKeywords: [Keyword]) throws -> NovelInformation {
        let authors = basicDTO.author
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // 장르는 `/`로 이어진 한 문자열("로맨스/로판")로 온다 → 쪼개서 각각 매핑.
        // (UI는 반대로 `displayName`을 `/`로 다시 이어 표기한다.)
        let genres = try basicDTO.novelGenres
            .components(separatedBy: "/")
            .map { try mapNovelGenre(from: $0.trimmingCharacters(in: .whitespaces)) }

        let novel = Novel(
            id: id,
            thumbnailImage: ImageURLResolver.resolve(from: basicDTO.novelImage),
            title: basicDTO.novelTitle,
            authors: authors,
            genres: genres,
            interestCount: basicDTO.interestCount,
            rating: basicDTO.novelRating,
            ratingCount: basicDTO.novelRatingCount,
            // 안 넘기면 기본값 nil = "비로그인" → 관심 토글이 조용히 no-op이 된다.
            isInterested: basicDTO.isUserNovelInterest
        )
        
        var userReview: UserNovelReview?
        if let readStatusString = basicDTO.readStatus {
            let readingStatus = try mapReadingStatus(from: readStatusString)
            let period = try mapReadingPeriod(startDate: basicDTO.startDate ?? "",
                                              endDate: basicDTO.endDate ?? "")
            let rating = try? Rating(Double(basicDTO.userNovelRating))

            userReview = UserNovelReview(
                readingStatus: readingStatus,
                rating: rating,
                // 유저 본인 선택값(매력포인트·키워드)은 이 응답에 없다 — detailDTO의 집계값을
                // 채워 넣지 말 것(내 평가가 아닌 독자 전체 값이라 의미가 다르다).
                attractivePoint: [],
                period: period,
                keywords: []
            )
        }
        
        let platforms = try detailDTO.platforms.map { try mapPlatform(from: $0) }
        
        return NovelInformation(
            novel: novel,
            feedCount: basicDTO.feedCount,
            publicationStatus: mapPublicationStatus(from: basicDTO.isNovelCompleted),
            userReview: userReview,
            description: detailDTO.novelDescription,
            platforms: platforms,
            attractivePoints: try detailDTO.attractivePoints.map { try mapAttractivePoint(from: $0) },
            keywords: mapKeywords(from: detailDTO.keywords, cachedKeywords: cachedKeywords),
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
    
}

//MARK: - Entity -> DTO

extension NovelMapper {
    
    // MARK: - 서재 조회 Query

    /// 타유저 서재의 고정 페이지 크기. 내 서재와 같은 엔드포인트라 값도 같은 곳(Domain 정책)에서 가져온다.
    private static let userLibraryPageSize = LibraryPageSizePolicy.pageSize

    /// 내 서재 V2 쿼리. 미적용 필터는 nil로 둬 파라미터를 생략한다(빈 배열 전송 금지 — DTO 주석 참조).
    /// isInterest는 "관심만 보기" 토글이라 true일 때만 전송한다(false를 보내면 비관심만 필터됨).
    ///
    /// `size`는 여기서 정하지 않고 **화면이 넘긴 값을 그대로 싣는다** — 재진입 갱신이 "보고 있던 개수만큼"
    /// 한 번에 받아야 해서 페이지 크기가 고정이 아니다(타유저 서재는 고정이라 아래에서 상수를 쓴다).
    static func myLibraryV2Query(from filter: MyLibraryFilter, cursor: String?, size: Int) -> UserLibraryV2Query {
        var ratingMin: Float?
        var ratingMax: Float?
        var unratedOnly: Bool?
        switch filter.rating {
        case .range(let min, let max):
            ratingMin = min
            ratingMax = max
        case .unratedOnly:
            unratedOnly = true
        case nil:
            break
        }

        return UserLibraryV2Query(
            cursor: cursor,
            // 서버와 말하는 마지막 지점에서 상한을 닫는다 — 화면이 정책을 거치는 게 정상 경로지만,
            // 그 선의에 기대지 않고 여기서도 막아야 새 호출자가 생겨도 상한이 새지 않는다.
            size: min(size, LibraryPageSizePolicy.maxSize),
            sortType: mapLibrarySortTypeString(from: filter.sortType),
            isInterest: filter.isInterest ? true : nil,
            readStatuses: filter.readingStatus.isEmpty
                ? nil : filter.readingStatus.map { mapReadingStatusString(from: $0) },
            genres: filter.genres.isEmpty
                ? nil : filter.genres.map { mapNovelGenreString(from: $0) },
            isCompleted: filter.publicationStatus.map { $0 == .completed },
            ratingMin: ratingMin,
            ratingMax: ratingMax,
            unratedOnly: unratedOnly,
            attractivePoints: filter.attractivePoint.isEmpty
                ? nil : filter.attractivePoint.map { mapAttractivePointString(from: $0) },
            // 서재 키워드 필터는 서버가 keywordName(한글명) 매칭 — 검색의 keywordIds와 다르다.
            keywords: filter.keywords.isEmpty ? nil : filter.keywords.map { $0.name }
        )
    }

    /// 타유저 서재 V2 쿼리. 내 서재와 **같은 엔드포인트**를 쓰지만 필터 UI가 없는 화면이라 정렬만 싣고
    /// 나머지 필터는 전부 nil로 둬 파라미터를 생략한다(빈 배열 전송 금지 — DTO 주석 참조).
    ///
    /// `size`가 여기만 상수인 건 의도다 — 이 화면은 push라 재진입마다 새로 서서 "보고 있던 개수만큼
    /// 다시 받기"가 존재하지 않는다(내 서재는 그래서 화면이 size를 넘긴다).
    static func userLibraryV2Query(from filter: LibraryFilter, cursor: String?) -> UserLibraryV2Query {
        UserLibraryV2Query(
            cursor: cursor,
            size: userLibraryPageSize,
            sortType: mapLibrarySortTypeString(from: filter.sortType),
            isInterest: nil,
            readStatuses: nil,
            genres: nil,
            isCompleted: nil,
            ratingMin: nil,
            ratingMax: nil,
            unratedOnly: nil,
            attractivePoints: nil,
            keywords: nil
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
        return value.rawValue.uppercased()
    }
    
    private static func mapAttractivePoint(from value: String) throws -> AttractivePoint {
        switch value {
        case "worldview":       return .worldview
        case "material":        return .material
        case "character":       return .character
        case "relationship":    return .relationship
        case "vibe":            return .vibe
        case "writingskill":    return .writingSkill
        default:                throw MappingError.invalidAttractivePoint(value)
        }
    }
    
    private static func mapAttractivePointString(from value: AttractivePoint) -> String {
        switch value {
        case .worldview:        return "worldview"
        case .material:         return "material"
        case .character:        return "character"
        case .relationship:     return "relationship"
        case .vibe:             return "vibe"
        case .writingSkill:     return "writingskill"
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
        
        do {
            return try ReadingPeriod(start: start, end: end)
        } catch {
            // 미래 날짜·역전 등 도메인 불변식 위반은 손상 데이터로 보고 매핑 실패로 변환(→ .invalidData).
            throw MappingError.invalidReadingPeriod(start: startDate, end: endDate)
        }
    }

    private static func mapLibrarySortTypeString(from value: LibrarySortType) -> String {
        switch value {
        case .registeredNewest:  return "created_desc"
        case .registeredOldest:  return "created_asc"
        case .title:             return "title"
        case .readDate:          return "read_date"
        case .ratingHighest:     return "rating_desc"
        case .ratingLowest:      return "rating_asc"
        }
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
        case "라노벨":   return .lightNovel
        case "무협":    return .wuxia
        case "판타지":   return .fantasy
        case "로맨스":   return .romance
        case "BL":     return .BL
        case "로판":    return .romanceFantasy
        case "현판":    return .modernFantasy
        case "드라마":   return .drama
        case "미스터리":  return .mystery
        default:        throw MappingError.invalidNovelGenre(value)
        }
    }
    
    private static func mapPublicationStatus(from isCompleted: Bool) -> NovelPublicationStatus {
        isCompleted ? .completed : .onGoing
    }
    
    private static func mapKeywords(from dtos: [NovelKeywordResponse],
                                    cachedKeywords: [Keyword]) -> [NovelKeyword] {
        dtos.compactMap { dto in
            cachedKeywords
                .first { $0.name == dto.keywordName }
                .map { NovelKeyword(keyword: $0, count: dto.keywordCount) }
        }
    }

    /// 서재 목록 API는 키워드 이름만 내려준다. 전체 키워드 캐시에서 동일한 이름의 ID를 찾아
    /// `UserNovelReview`에 넣을 값을 복원하며, 서버에 없는 이름은 표시하지 않는다.
    private static func mapKeywords(from names: [String], cachedKeywords: [Keyword]) -> [Keyword] {
        names.compactMap { name in
            cachedKeywords.first { $0.name == name }
        }
    }
    
    private static func mapPlatform(from dto: NovelPlatformResponse) throws -> NovelPlatform {
        guard let url = URL(string: dto.platformUrl) else {
            throw MappingError.invalidPlatformUrl(dto.platformUrl)
        }
        return NovelPlatform(
            name: dto.platformName,
            // 서버가 버킷 상대 경로(예: /platform/naver-series)로 주면 @스케일x.png로 완성한다.
            image: ImageURLResolver.resolve(from: dto.platformImage),
            url: url
        )
    }
}
