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

    // MARK: - Action

    enum Action {
        case toggleGenre(NovelGenre)
        case togglePlatform(NovelPlatform)
        case togglePublicationStatus(NovelPublicationStatus)
        case changeRatingRange(min: Float, max: Float)
        case setKeywords([Keyword])
        case clearAll
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Init

    init(filter: SearchFilter = SearchFilter()) {
        var ratingMin = NovelRatingRange.bounds.lowerBound
        var ratingMax = NovelRatingRange.bounds.upperBound
        if let range = filter.ratingRange {
            ratingMin = range.min
            ratingMax = range.max
        }
        self.state = State(filter: filter, ratingMin: ratingMin, ratingMax: ratingMax)
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
        case .clearAll:
            clearAll()
        }
    }
}

// MARK: - Action Handling

private extension DetailSearchFilterViewModel {
    func toggleGenre(_ genre: NovelGenre) {
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
        if state.filter.publicationStatus == status {
            state.filter.setPublicationStatus(nil)
        } else {
            state.filter.setPublicationStatus(status)
        }
    }

    func changeRatingRange(min: Float, max: Float) {
        state.ratingMin = min
        state.ratingMax = max
        state.filter.setRatingRange(min: min, max: max)
    }

    /// "초기화" — 정보 탭 4종(장르·플랫폼·연재상태·별점) + 키워드 탭(외부 콘텐츠에서 반영된 선택)까지 전체
    /// 리셋. `SearchFilter`는 `MyLibraryFilter`와 달리 "시트 밖" 상태 구분이 없어 `clearAll()`이 전체를 초기화한다.
    func clearAll() {
        state.filter.clearAll()
        state.ratingMin = NovelRatingRange.bounds.lowerBound
        state.ratingMax = NovelRatingRange.bounds.upperBound
    }
}
