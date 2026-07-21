//
//  LibraryFilterSheetViewModel.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NovelDomain

/// 필터 탭 식별 — 메인 화면 칩에서 특정 탭으로 바로 진입할 때도 쓴다.
enum LibraryFilterTab: CaseIterable, Equatable {
    case readingStatus
    case genre
    case publicationStatus
    case rating
    case attractivePoint
    case keyword
}

// 필터 시트 전용 순수 입력 VM — UseCase·콜백 없이 필터 편집본만 소유한다(ReadingPeriodSheet 패턴).
// 부모 현재 필터의 복사본에서 시작하고, "작품 찾기" 확정 시 View가 `state.filter`를 부모 onApply로 올린다.
// 등록 키워드 목록은 부모 VM이 로드해 View 주입으로 내려온다 — 시트는 서버를 모른다.
@MainActor
@Observable
final class LibraryFilterSheetViewModel {

    // MARK: - State

    struct State {
        var selectedTab: LibraryFilterTab
        var filter: MyLibraryFilter
        /// 별점 탭 슬라이더 편집값 — 필터 미설정(nil)이어도 슬라이더는 전체 범위를 보여야 해서 분리 보유.
        var ratingMin: Float
        var ratingMax: Float
    }

    // MARK: - Derived

    /// 슬라이더 비활성 여부 — "별점 없음" 토글이 켜져 있으면 범위 편집이 잠긴다.
    var isUnratedOnly: Bool { state.filter.rating == .unratedOnly }

    /// 탭별 활성 필터 여부(탭 라벨 옆 보라 점 표시용).
    func hasActiveFilter(in tab: LibraryFilterTab) -> Bool {
        switch tab {
        case .readingStatus:     !state.filter.readingStatus.isEmpty
        case .genre:             !state.filter.genres.isEmpty
        case .publicationStatus: state.filter.publicationStatus != nil
        case .rating:            state.filter.rating != nil
        case .attractivePoint:   !state.filter.attractivePoint.isEmpty
        case .keyword:           !state.filter.keywords.isEmpty
        }
    }

    // MARK: - Action

    enum Action {
        case selectTab(LibraryFilterTab)
        case toggleReadingStatus(ReadingStatus)
        case toggleGenre(NovelGenre)
        case togglePublicationStatus(NovelPublicationStatus)
        case changeRatingRange(min: Float, max: Float)
        case toggleUnratedOnly
        case toggleAttractivePoint(AttractivePoint)
        case toggleKeyword(Keyword)
        case removeChip(Chip)
        case clearAll
    }

    /// 선택 칩 행의 칩 하나 — 어떤 필터의 어떤 값인지 의미값으로 식별한다(카피는 View가 매핑).
    enum Chip: Equatable, Hashable {
        case readingStatus(ReadingStatus)
        case genre(NovelGenre)
        case publicationStatus(NovelPublicationStatus)
        case rating(LibraryRatingFilter)
        case attractivePoint(AttractivePoint)
        case keyword(Keyword)
    }

    /// 현재 활성 필터 전체를 칩 목록으로 (탭 순서대로).
    var chips: [Chip] {
        var result: [Chip] = []
        result += state.filter.readingStatus.map { .readingStatus($0) }
        result += state.filter.genres.map { .genre($0) }
        if let status = state.filter.publicationStatus { result.append(.publicationStatus(status)) }
        if let rating = state.filter.rating { result.append(.rating(rating)) }
        result += state.filter.attractivePoint.map { .attractivePoint($0) }
        result += state.filter.keywords.map { .keyword($0) }
        return result
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Init

    init(filter: MyLibraryFilter, initialTab: LibraryFilterTab) {
        var ratingMin = MyLibraryFilter.ratingRangeBounds.lowerBound
        var ratingMax = MyLibraryFilter.ratingRangeBounds.upperBound
        if case let .range(min, max) = filter.rating {
            ratingMin = min
            ratingMax = max
        }
        self.state = State(
            selectedTab: initialTab,
            filter: filter,
            ratingMin: ratingMin,
            ratingMax: ratingMax
        )
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .selectTab(let tab):
            state.selectedTab = tab
        case .toggleReadingStatus(let status):
            toggleReadingStatus(status)
        case .toggleGenre(let genre):
            toggleGenre(genre)
        case .togglePublicationStatus(let status):
            togglePublicationStatus(status)
        case .changeRatingRange(let min, let max):
            changeRatingRange(min: min, max: max)
        case .toggleUnratedOnly:
            toggleUnratedOnly()
        case .toggleAttractivePoint(let point):
            toggleAttractivePoint(point)
        case .toggleKeyword(let keyword):
            toggleKeyword(keyword)
        case .removeChip(let chip):
            removeChip(chip)
        case .clearAll:
            clearAll()
        }
    }
}

// MARK: - Action Handling

private extension LibraryFilterSheetViewModel {

    func toggleReadingStatus(_ status: ReadingStatus) {
        if state.filter.readingStatus.contains(status) {
            state.filter.removeReadingStatus(status)
        } else {
            state.filter.addReadingStatus(status)
        }
    }

    func toggleGenre(_ genre: NovelGenre) {
        if state.filter.genres.contains(genre) {
            state.filter.removeGenre(genre)
        } else {
            state.filter.addGenre(genre)
        }
    }

    /// 연재 상태는 단일 선택 — 같은 값을 다시 탭하면 해제한다.
    func togglePublicationStatus(_ status: NovelPublicationStatus) {
        if state.filter.publicationStatus == status {
            state.filter.setPublicationStatus(nil)
        } else {
            state.filter.setPublicationStatus(status)
        }
    }

    /// 슬라이더 변경 — 도메인이 전체 범위(0.0~5.0)를 "필터 없음"으로 정규화한다.
    func changeRatingRange(min: Float, max: Float) {
        state.ratingMin = min
        state.ratingMax = max
        state.filter.setRatingRange(min: min, max: max)
    }

    func toggleUnratedOnly() {
        if isUnratedOnly {
            // 토글 해제 → 슬라이더 편집값으로 복원(전체 범위면 도메인이 nil로 정규화).
            state.filter.setRatingRange(min: state.ratingMin, max: state.ratingMax)
        } else {
            state.filter.setUnratedOnly()
        }
    }

    func toggleAttractivePoint(_ point: AttractivePoint) {
        if state.filter.attractivePoint.contains(point) {
            state.filter.removeAttractivePoint(point)
        } else {
            state.filter.addAttractivePoint(point)
        }
    }

    func toggleKeyword(_ keyword: Keyword) {
        if state.filter.keywords.contains(keyword) {
            state.filter.removeKeyword(keyword)
        } else {
            state.filter.addKeyword(keyword)
        }
    }

    func removeChip(_ chip: Chip) {
        switch chip {
        case .readingStatus(let status):
            state.filter.removeReadingStatus(status)
        case .genre(let genre):
            state.filter.removeGenre(genre)
        case .publicationStatus:
            state.filter.setPublicationStatus(nil)
        case .rating:
            state.filter.clearRating()
            state.ratingMin = MyLibraryFilter.ratingRangeBounds.lowerBound
            state.ratingMax = MyLibraryFilter.ratingRangeBounds.upperBound
        case .attractivePoint(let point):
            state.filter.removeAttractivePoint(point)
        case .keyword(let keyword):
            state.filter.removeKeyword(keyword)
        }
    }

    /// 시트 "초기화" — 시트 필터 6종만 리셋(관심·정렬 유지, 도메인 clearAll 규칙).
    func clearAll() {
        state.filter.clearAll()
        state.ratingMin = MyLibraryFilter.ratingRangeBounds.lowerBound
        state.ratingMax = MyLibraryFilter.ratingRangeBounds.upperBound
    }
}
