//
//  DetailSearchFilterViewModel.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import SearchDomain
import Analytics

/// 상세탐색 필터(정보 탭) 전용 순수 입력 VM — UseCase 없이 필터 편집본만 소유한다(`LibraryFilterSheetViewModel` 패턴).
/// "작품 찾기" 확정은 View가 `state.filter`를 그대로 읽어 위임한다(콜백은 View가 보유, `LibraryFilterSheet`의
/// `onApply` 패턴과 동일).
@MainActor
@Observable
final class DetailSearchFilterViewModel {

    // MARK: - State

    struct State {
        var filter: SearchFilter
        /// 별점 슬라이더 편집값 — 필터 미설정(nil)이어도 슬라이더는 전체 범위를 보여야 해서 분리 보유.
        var ratingMin: Float
        var ratingMax: Float
    }

    // MARK: - Derived

    /// "정보" 탭에 선택된 항목이 하나라도 있는지 — 장르·플랫폼·연재상태·별점 4종만 본다(이 탭이 다루는 필드).
    var hasActiveInfoFilter: Bool {
        !state.filter.genres.isEmpty
            || !state.filter.platforms.isEmpty
            || state.filter.publicationStatus != nil
            || state.filter.ratingRange != nil
    }

    /// "키워드" 탭에 선택된 항목이 있는지 — `keywordTabContent`의 `onSelectionChanged`로 갱신되는
    /// `SearchFilter.keywords` 기준으로 판단한다.
    var hasActiveKeywordFilter: Bool {
        !state.filter.keywords.isEmpty
    }

    // MARK: - Action

    enum Action {
        case toggleGenre(NovelGenre)
        case togglePlatform(NovelPlatform)
        case togglePublicationStatus(NovelPublicationStatus)
        case changeRatingRange(min: Float, max: Float)
        case setKeywords([Keyword])
        case clearInfoFilters
        case clearKeywords
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Dependency

    private let analyticsTracker: AnalyticsTracker?

    // MARK: - Init

    init(filter: SearchFilter = SearchFilter(), analyticsTracker: AnalyticsTracker? = nil) {
        var ratingMin = NovelRatingRange.bounds.lowerBound
        var ratingMax = NovelRatingRange.bounds.upperBound
        if let range = filter.ratingRange {
            ratingMin = range.min
            ratingMax = range.max
        }
        self.analyticsTracker = analyticsTracker
        self.state = State(filter: filter, ratingMin: ratingMin, ratingMax: ratingMax)
    }

    /// 이벤트 트래킹 pass-through(#249) — `state`를 건드리지 않아 `handle(_:)`을 거치지 않는다.
    func track(_ event: SearchAnalyticsEvent, properties: [String: AnalyticsPropertyValue]? = nil) {
        analyticsTracker?.track(event, properties: properties)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .toggleGenre(let genre):
            toggleGenre(genre)
        case .togglePlatform(let platform):
            togglePlatform(platform)
        case .togglePublicationStatus(let status):
            togglePublicationStatus(status)
        case .changeRatingRange(let min, let max):
            changeRatingRange(min: min, max: max)
        case .setKeywords(let keywords):
            state.filter.setKeywords(keywords)
        case .clearInfoFilters:
            clearInfoFilters()
        case .clearKeywords:
            state.filter.clearKeywords()
        }
    }
}

// MARK: - Action Handling

private extension DetailSearchFilterViewModel {
    func toggleGenre(_ genre: NovelGenre) {
        track(.infoGenreSelected)
        if state.filter.genres.contains(genre) {
            state.filter.removeGenre(genre)
        } else {
            state.filter.addGenre(genre)
        }
    }

    func togglePlatform(_ platform: NovelPlatform) {
        if state.filter.platforms.contains(platform) {
            state.filter.removePlatform(platform)
        } else {
            state.filter.addPlatform(platform)
        }
    }

    /// 연재상태는 단일 선택 — 같은 값을 다시 탭하면 해제한다.
    func togglePublicationStatus(_ status: NovelPublicationStatus) {
        track(.infoPublicationStatusSelected)
        if state.filter.publicationStatus == status {
            state.filter.setPublicationStatus(nil)
        } else {
            state.filter.setPublicationStatus(status)
        }
    }

    /// ⚠️ `WSSRangeSlider.onChange`는 드래그 중 **매 픽셀마다** 불린다 — 값이 실제로 스텝을 넘었을 때만
    /// 트래킹한다(슬라이더 자신의 `triggerHapticIfStepChanged`와 같은 이유의 가드, 안 걸면 드래그 한 번에
    /// 수십~수백 건이 쌓인다).
    func changeRatingRange(min: Float, max: Float) {
        if min != state.ratingMin || max != state.ratingMax {
            track(.infoRatingChanged)
        }
        state.ratingMin = min
        state.ratingMax = max
        state.filter.setRatingRange(min: min, max: max)
    }

    /// "초기화"(정보 탭) — 이 탭이 소유한 4종(장르·플랫폼·연재상태·별점 범위)만 리셋한다. 키워드 탭은
    /// 보고 있는 탭만 각자 초기화되도록 `.clearKeywords`로 독립적으로 처리한다(사용자 확정, #185).
    func clearInfoFilters() {
        state.filter.clearInfoFilters()
        state.ratingMin = NovelRatingRange.bounds.lowerBound
        state.ratingMax = NovelRatingRange.bounds.upperBound
    }
}
