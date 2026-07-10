//
//  NovelDetailViewModel.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import NovelDomain
import Logger

@MainActor
@Observable
final class NovelDetailViewModel {

    // MARK: - State

    struct State {
        /// 작품 상세 집합 정보. 로드 전 nil.
        var information: NovelInformation?
        /// 관심 토글이 반영되는 작품 기본 정보.
        /// `NovelInformation.novel`은 let이라 토글 정책(`Novel.toggleInterest`)을 적용할 수 없어 분리 보유한다.
        var novel: Novel?
        var selectedTab: Tab = .info
        var feeds: [TotalFeed] = []
        var hasNextFeeds = true
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 실패 뷰(`information == nil && !isLoading`)가 스친다.
        var isLoading = true
        var isLoadingFeeds = false
        /// 피드 첫 페이지 로드 실패 여부 — View가 "빈 목록"과 "로드 실패"를 구분해 그리기 위한 상태.
        /// (더보기 실패는 기존 목록을 유지하므로 토스트만 띄우고 이 값은 건드리지 않는다.)
        var feedsLoadFailed = false
        var shouldDismiss = false
        /// 표시할 에러(의미값). 표현(토스트) 매핑은 View가 한다(얇은 ViewModel).
        /// 작품 본체 로드 실패는 전면 실패 뷰(`information == nil && !isLoading`)가 표현하므로 여기 없다.
        var presentedError: DetailError?
    }

    enum Tab: CaseIterable, Equatable {
        case info
        case feed
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현은 View가 결정한다.
    /// 두 경우 모두 네트워크 실패로 정상 도달 가능한 경로다(도달 불가 가정으로 뭉치지 않고 맥락을 남긴다).
    enum DetailError: Equatable {
        case feedsLoadFailed
        case interestFailed
    }

    // MARK: - Action

    enum Action {
        case load
        case selectTab(Tab)
        case toggleInterest
        case loadMoreFeeds
        case requestClose
        case dismissError
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    // 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다(NovelReview 교훈).
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var hasLoadedFirstFeeds = false
    @ObservationIgnored private var isSyncingInterest = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    @ObservationIgnored private var isClosing = false

    // MARK: - Dependency

    private let novelID: NovelID
    private let logger: Logger?

    // NovelDomain
    private let loadNovelUseCase: LoadNovelUseCase
    private let novelInterestUseCase: NovelInterestUseCase

    // FeedDomain
    private let loadNovelFeedsUseCase: LoadNovelFeedsUseCase

    // MARK: - Init

    init(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        logger: Logger? = nil
    ) {
        self.novelID = novelID
        self.loadNovelUseCase = loadNovelUseCase
        self.novelInterestUseCase = novelInterestUseCase
        self.loadNovelFeedsUseCase = loadNovelFeedsUseCase
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .selectTab(let tab):
            selectTab(tab)
        case .toggleInterest:
            toggleInterest()
        case .loadMoreFeeds:
            loadMoreFeeds()
        case .requestClose:
            close()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension NovelDetailViewModel {

    /// 진입 시 상세 로드. onAppear는 재진입마다 불리므로 성공 후에는 다시 로드하지 않되,
    /// 실패는 가드를 소진하지 않아 재진입 시 재시도가 열려 있다.
    func load() {
        guard !hasLoaded, loadTask == nil, !isClosing else { return }
        state.isLoading = true
        loadTask = Task { await loadNovel() }
    }

    /// 탭 전환. 피드 탭은 첫 성공 전까지 진입(재탭 포함)마다 첫 페이지 로드를 시도한다.
    func selectTab(_ tab: Tab) {
        state.selectedTab = tab
        if tab == .feed, !hasLoadedFirstFeeds, feedsTask == nil, !isClosing {
            state.isLoadingFeeds = true
            feedsTask = Task { await loadFeeds(after: nil) }
        }
    }

    /// 관심 토글. 정책(카운트 증감·중복 방지)은 엔티티 `Novel`에 위임하고,
    /// UI에는 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다.
    func toggleInterest() {
        guard !isSyncingInterest, !isClosing, var novel = state.novel else { return }
        let before = novel
        novel.toggleInterest()
        // isInterested가 nil이면 엔티티 정책상 변화가 없다(비로그인 등) → 서버 호출도 하지 않는다.
        guard novel.isInterested != before.isInterested else { return }

        state.novel = novel
        isSyncingInterest = true
        Task { await syncInterest(to: novel.isInterested == true, rollbackTo: before) }
    }

    /// 피드 다음 페이지. `lastFeedID` 커서는 현재 목록의 마지막 피드.
    func loadMoreFeeds() {
        guard state.hasNextFeeds,
              feedsTask == nil,
              !isClosing,
              let lastFeedID = state.feeds.last?.feedId else { return }
        state.isLoadingFeeds = true
        feedsTask = Task { await loadFeeds(after: lastFeedID) }
    }

    /// 뒤로가기 요청. 진행 중인 로드를 취소하고 닫기 신호만 View로 발화한다.
    func close() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        feedsTask?.cancel()
        state.shouldDismiss = true
    }
}

// MARK: - UseCase Handling

private extension NovelDetailViewModel {

    func loadNovel() async {
        defer {
            loadTask = nil
            if !isClosing { state.isLoading = false }
        }
        do {
            let information = try await loadNovelUseCase.execute(id: novelID)
            guard !isClosing, !Task.isCancelled else { return }
            state.information = information
            state.novel = information.novel
            hasLoaded = true
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            // 본체 로드 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
            logger?.error("NovelDetail 실패(novelLoad): \(String(describing: error))")
        }
    }

    /// 피드 목록 로드. `after == nil`이면 첫 페이지(커서 0 — 서버 규약).
    func loadFeeds(after lastFeedID: FeedID?) async {
        defer {
            feedsTask = nil
            if !isClosing { state.isLoadingFeeds = false }
        }
        do {
            let page = try await loadNovelFeedsUseCase.execute(
                novelID: novelID,
                lastFeedID: lastFeedID ?? FeedID(0)
            )
            guard !isClosing, !Task.isCancelled else { return }
            state.feeds.append(contentsOf: page.items)
            state.hasNextFeeds = page.hasNext
            state.feedsLoadFailed = false
            if lastFeedID == nil { hasLoadedFirstFeeds = true }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if lastFeedID == nil { state.feedsLoadFailed = true }
            presentError(error, as: .feedsLoadFailed)
        }
    }

    /// 관심 상태 서버 동기화. 실패하면 낙관 반영을 롤백한다.
    func syncInterest(to isInterested: Bool, rollbackTo before: Novel) async {
        defer { isSyncingInterest = false }
        do {
            if isInterested {
                try await novelInterestUseCase.add(id: novelID)
            } else {
                try await novelInterestUseCase.remove(id: novelID)
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            state.novel = before
            presentError(error, as: .interestFailed)
        }
    }
}

// MARK: - Error Mapping

private extension NovelDetailViewModel {

    /// Repository 에러를 발생 맥락의 의미 에러로 변환한다. 원인은 로그로 남긴다.
    /// (`handle(_:)`과 이름이 겹치지 않게 분리)
    func presentError(_ error: Error, as presented: DetailError) {
        logger?.error("NovelDetail 실패(\(presented)): \(String(describing: error))")
        if state.presentedError != nil { return }
        state.presentedError = presented
    }
}
