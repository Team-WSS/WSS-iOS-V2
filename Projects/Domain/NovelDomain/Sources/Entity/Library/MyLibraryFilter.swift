//
//  MyLibraryFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 내 서재 조회 필터 (V2).
///
/// 시트 필터 6종(읽기상태·장르·연재상태·별점·매력포인트·키워드)과
/// 시트 밖 상태 2종(관심 토글·정렬)을 함께 담는다.
/// `clearAll()`(시트 "초기화")은 **시트 필터 6종만** 리셋한다 — 관심·정렬은 시트 소속이 아니다.
public struct MyLibraryFilter: Equatable, Sendable {

    public private(set) var isInterest: Bool
    public private(set) var readingStatus: [ReadingStatus]
    public private(set) var genres: [NovelGenre]
    public private(set) var publicationStatus: NovelPublicationStatus?
    public private(set) var rating: LibraryRatingFilter?
    public private(set) var attractivePoint: [AttractivePoint]
    public private(set) var keywords: [Keyword]
    public private(set) var sortType: LibrarySortType

    public init(
        isInterest: Bool = false,
        readingStatus: [ReadingStatus] = [],
        genres: [NovelGenre] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        rating: LibraryRatingFilter? = nil,
        attractivePoint: [AttractivePoint] = [],
        keywords: [Keyword] = [],
        sortType: LibrarySortType = .registeredNewest
    ) {
        self.isInterest = isInterest
        self.readingStatus = readingStatus
        self.genres = genres
        self.publicationStatus = publicationStatus
        self.rating = rating
        self.attractivePoint = attractivePoint
        self.keywords = keywords
        self.sortType = sortType
    }

    // MARK: - Policy

    // - isInterest (관심)

    public mutating func toggleInterest() {
        isInterest.toggle()
    }

    // - reading status (읽기상태)

    public mutating func addReadingStatus(_ newStatus: ReadingStatus) {
        guard !readingStatus.contains(newStatus) else { return }

        readingStatus.append(newStatus)
    }

    public mutating func removeReadingStatus(_ targetReadStatus: ReadingStatus) {
        readingStatus.removeAll { $0 == targetReadStatus }
    }

    private mutating func clearReadingStatuses() {
        readingStatus.removeAll()
    }

    // - genres (장르)

    public mutating func addGenre(_ newGenre: NovelGenre) {
        guard !genres.contains(newGenre) else { return }

        genres.append(newGenre)
    }

    public mutating func removeGenre(_ targetGenre: NovelGenre) {
        genres.removeAll { $0 == targetGenre }
    }

    private mutating func clearGenres() {
        genres.removeAll()
    }

    // - publication status (연재상태, 단일 선택)

    public mutating func setPublicationStatus(_ status: NovelPublicationStatus?) {
        publicationStatus = status
    }

    private mutating func clearPublicationStatus() {
        publicationStatus = nil
    }

    // - rating (별점)

    public static let ratingRangeBounds: ClosedRange<Float> = 0.0...5.0

    /// 별점 범위를 설정한다. 경계를 벗어나면 경계로 보정하고, min > max면 무시한다.
    /// 전체 범위(0.0~5.0)는 "필터 없음"과 같은 뜻이므로 nil로 정규화한다 (표현 단일화).
    public mutating func setRatingRange(min: Float, max: Float) {
        let bounds = Self.ratingRangeBounds
        let clampedMin = Swift.min(Swift.max(min, bounds.lowerBound), bounds.upperBound)
        let clampedMax = Swift.min(Swift.max(max, bounds.lowerBound), bounds.upperBound)
        guard clampedMin <= clampedMax else { return }

        if clampedMin == bounds.lowerBound && clampedMax == bounds.upperBound {
            rating = nil
        } else {
            rating = .range(min: clampedMin, max: clampedMax)
        }
    }

    /// "별점 등록 안 된 작품만 보기" — 범위 필터를 대체한다.
    public mutating func setUnratedOnly() {
        rating = .unratedOnly
    }

    public mutating func clearRating() {
        rating = nil
    }

    // - attractive point (매력포인트)

    public mutating func addAttractivePoint(_ newAttractivePoint: AttractivePoint) {
        guard !attractivePoint.contains(newAttractivePoint) else { return }

        attractivePoint.append(newAttractivePoint)
    }

    public mutating func removeAttractivePoint(_ targetAttractivePoint: AttractivePoint) {
        attractivePoint.removeAll { $0 == targetAttractivePoint }
    }

    private mutating func clearAttractivePoints() {
        attractivePoint.removeAll()
    }

    // - keywords (키워드 — 서재에 등록한 키워드에서 선택)

    public mutating func addKeyword(_ newKeyword: Keyword) {
        guard !keywords.contains(newKeyword) else { return }

        keywords.append(newKeyword)
    }

    public mutating func removeKeyword(_ targetKeyword: Keyword) {
        keywords.removeAll { $0 == targetKeyword }
    }

    private mutating func clearKeywords() {
        keywords.removeAll()
    }

    // - sort type (정렬)

    public mutating func setSortType(_ sortType: LibrarySortType) {
        self.sortType = sortType
    }

    // - Clear (시트 "초기화" — 관심·정렬은 유지)

    public mutating func clearAll() {
        clearReadingStatuses()
        clearGenres()
        clearPublicationStatus()
        clearRating()
        clearAttractivePoints()
        clearKeywords()
    }

    /// 시트 필터 6종 중 하나라도 걸려 있는지 (시트 진입점 뱃지 등 표시용 의미값).
    public var hasActiveSheetFilter: Bool {
        !readingStatus.isEmpty
            || !genres.isEmpty
            || publicationStatus != nil
            || rating != nil
            || !attractivePoint.isEmpty
            || !keywords.isEmpty
    }
}
