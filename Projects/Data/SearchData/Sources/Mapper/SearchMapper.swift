//
//  SearchMapper.swift
//  SearchData
//
//  Created by Seoyeon Choi on 7/20/26.
//

import Foundation

import SearchDomain
import BaseDomain
import BaseData

public enum SearchMapper {

    // MARK: - 최근 검색어

    public static func recentSearchWords(from dto: RecentSearchWordsResponse) -> [RecentSearchWord] {
        dto.recentSearches.map { recentSearchWord(from: $0) }
    }

    static func recentSearchWord(from dto: RecentSearchWordResponse) -> RecentSearchWord {
        RecentSearchWord(id: SearchWordID(dto.id),
                         title: dto.keyword)
    }

    // MARK: - 검색어 자동완성

    public static func searchAutoCompletionWords(from dto: SearchAutoCompletionWordsResponse) -> [SearchAutoCompletionWord] {
        dto.keywords.map { SearchAutoCompletionWord(word: $0) }
    }

    // MARK: - 작품 검색

    public static func searchNovels(from dto: SearchNovelsResponse) -> (Paginated<Novel>, Int) {
        let novels = dto.novels.map { searchNovel(from: $0) }
        let paginated = Paginated(items: novels, hasNext: dto.isLoadable)
        return (paginated, dto.resultCount)
    }

    public static func searchNovel(from dto: SearchNovelResponse) -> Novel {
        let thumbnailImageURL = ImageURLResolver.resolve(from: dto.novelImage)
        let authors = dto.author
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        return Novel(
            id: NovelID(dto.novelId),
            thumbnailImage: thumbnailImageURL,
            title: dto.title,
            authors: authors,
            genres: [], // dto값에 장르 값이 포함되지 않음
            interestCount: dto.interestCount,
            rating: dto.novelRating,
            ratingCount: dto.novelRatingCount
        )
    }

    static func detailSearchQuery(from filter: SearchFilter, page: Int) -> DetailSearchQuery {
        DetailSearchQuery(
            genres: filter.genres.map { mapNovelGenreString(from: $0) },
            isCompleted: filter.publicationStatus == .completed,
            novelRating: filter.ratingThreshold?.rawValue ?? 0,
            keywordIds: filter.keywords.map { $0.id.value },
            page: page,
            size: 20
        )
    }

    private static func mapNovelGenreString(from genre: NovelGenre) -> String {
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
}
