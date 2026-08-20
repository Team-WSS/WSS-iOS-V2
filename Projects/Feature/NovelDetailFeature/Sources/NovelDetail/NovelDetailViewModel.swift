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
import NovelReviewDomain
import SocialDomain
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
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// 어느 서버 호출에서 발생하든 여기로 모이며, View가 `onChange`로 소비한다(`shouldDismiss`와 대칭).
        var requiresAuthentication = false
        /// 평가 삭제 확인 알럿 표시 여부 — 삭제 가능 판단(평가 존재)이 필요해 VM이 소유한다.
        var isDeleteReviewAlertPresented = false
        /// 피드 셀 액션(삭제/신고)의 확인·완료 알럿 — 확정 시 실행할 대상 피드를 함께 보관한다.
        var presentedFeedAlert: FeedAlert?
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 작품 본체 로드 실패는 전면 실패 뷰(`information == nil && !isLoading`)가 표현하므로 여기 없다.
        var presentedToast: DetailToast?
    }

    enum Tab: CaseIterable, Equatable {
        case info
        case feed
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    /// 실패들은 모두 네트워크 실패로 정상 도달 가능한 경로다(도달 불가 가정으로 뭉치지 않고 맥락을 남긴다).
    /// ⚠️ **피드 로드 실패는 여기 없다** — 첫 페이지든 더보기든 탭 자리에 `NetworkErrorView`(재시도 버튼)로
    /// 표현한다. 남은 토스트는 전부 **사용자 액션의 실패/완료**다(→ Feature CLAUDE.md "로드 실패 표현 계약").
    enum DetailToast: Equatable {
        case interestFailed
        case deleteReviewFailed
        case likeFailed
        case deleteFeedFailed
        case reportFeedFailed
        /// 평가 삭제 완료 — 결과가 화면 재로드로만 보이면 알아차리기 어려워 성공도 토스트로 알린다.
        case reviewDeleted
    }

    /// 피드 셀 액션의 알럿 **의미값**. 카피·버튼 구성 매핑은 View가 한다.
    /// 신고는 확인 → API 성공 → 접수 완료의 2단 알럿이라 완료 케이스가 따로 있다(문구가 종류별로 다름).
    enum FeedAlert: Equatable {
        case deleteFeed(FeedID)
        case reportSpoiler(FeedID)
        case reportImproper(FeedID)
        case reportSpoilerCompleted
        case reportImproperCompleted
    }

    // MARK: - Action

    enum Action {
        case load
        case selectTab(Tab)
        case toggleInterest
        case loadMoreFeeds
        /// 피드 실패 뷰의 재시도 — 첫 페이지부터 다시 세운다.
        case retryFeeds
        case toggleFeedLike(FeedID)
        case deleteFeedTapped(FeedID)
        case reportSpoilerFeedTapped(FeedID)
        case reportImproperFeedTapped(FeedID)
        case confirmFeedAlert
        case dismissFeedAlert
        case deleteReviewTapped
        case confirmDeleteReview
        case dismissDeleteReviewAlert
        case requestClose
        case dismissToast
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
    @ObservationIgnored private var deleteReviewTask: Task<Void, Never>?
    /// 피드 삭제/신고는 한 번에 하나만 — 알럿을 거치므로 동시에 두 개가 뜰 일이 없다.
    @ObservationIgnored private var feedActionTask: Task<Void, Never>?
    /// 좋아요는 셀별 독립 동기화 — 같은 피드의 연타만 막고 다른 피드는 병행을 허용한다.
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    @ObservationIgnored private var isClosing = false

    // MARK: - Dependency

    private let novelID: NovelID
    private let logger: Logger?

    // NovelDomain
    private let loadNovelUseCase: LoadNovelUseCase
    private let novelInterestUseCase: NovelInterestUseCase

    // FeedDomain
    private let loadNovelFeedsUseCase: LoadNovelFeedsUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase

    // NovelReviewDomain
    private let deleteNovelReviewUseCase: DeleteNovelReviewUseCase

    // SocialDomain
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase

    // MARK: - Init

    init(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        deleteNovelReviewUseCase: DeleteNovelReviewUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) {
        self.novelID = novelID
        self.loadNovelUseCase = loadNovelUseCase
        self.novelInterestUseCase = novelInterestUseCase
        self.loadNovelFeedsUseCase = loadNovelFeedsUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.deleteFeedUseCase = deleteFeedUseCase
        self.deleteNovelReviewUseCase = deleteNovelReviewUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
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
        case .retryFeeds:
            retryFeeds()
        case .toggleFeedLike(let feedID):
            toggleFeedLike(feedID)
        case .deleteFeedTapped(let feedID):
            presentFeedAlert(.deleteFeed(feedID))
        case .reportSpoilerFeedTapped(let feedID):
            presentFeedAlert(.reportSpoiler(feedID))
        case .reportImproperFeedTapped(let feedID):
            presentFeedAlert(.reportImproper(feedID))
        case .confirmFeedAlert:
            confirmFeedAlert()
        case .dismissFeedAlert:
            state.presentedFeedAlert = nil
        case .deleteReviewTapped:
            presentDeleteReviewAlert()
        case .confirmDeleteReview:
            confirmDeleteReview()
        case .dismissDeleteReviewAlert:
            state.isDeleteReviewAlertPresented = false
        case .requestClose:
            close()
        case .dismissToast:
            state.presentedToast = nil
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

    /// 피드 실패 뷰의 재시도 — **첫 페이지부터 다시 세운다.**
    /// 더보기가 실패했을 때도 이 경로로 오므로 기존 목록을 비워야 같은 피드가 두 번 붙지 않는다.
    func retryFeeds() {
        guard feedsTask == nil, !isClosing else { return }

        state.feeds = []
        state.hasNextFeeds = true
        state.feedsLoadFailed = false
        hasLoadedFirstFeeds = false
        state.isLoadingFeeds = true
        feedsTask = Task { await loadFeeds(after: nil) }
    }

    /// 피드 좋아요 토글. 정책(카운트 증감·음수 방지)은 엔티티 `TotalFeed.toggleLike()`에 위임하고,
    /// UI에 낙관적으로 먼저 반영한 뒤 서버 동기화 실패 시 롤백한다(관심 토글과 같은 패턴).
    func toggleFeedLike(_ feedID: FeedID) {
        guard !isClosing,
              !syncingLikeFeedIDs.contains(feedID),
              let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) else { return }
        let before = state.feeds[index]
        var feed = before
        // 정책 위반(카운트 음수)이면 반영하지 않는다 — 서버 호출도 없다.
        guard (try? feed.toggleLike()) != nil else { return }

        state.feeds[index] = feed
        syncingLikeFeedIDs.insert(feedID)
        Task { await syncFeedLike(to: feed.isLiked, feedID: feedID, rollbackTo: before) }
    }

    /// 피드 삭제/신고 확인 알럿 표시. 진행 중인 액션이 있으면 무시한다.
    func presentFeedAlert(_ alert: FeedAlert) {
        guard !isClosing, feedActionTask == nil else { return }
        state.presentedFeedAlert = alert
    }

    /// 알럿에서 확정. 접수 완료 알럿(1버튼)의 "확인"은 dismiss로만 들어오므로 여기 오지 않는다.
    func confirmFeedAlert() {
        guard let alert = state.presentedFeedAlert else { return }
        state.presentedFeedAlert = nil
        guard feedActionTask == nil, !isClosing else { return }
        switch alert {
        case .deleteFeed(let feedID):
            feedActionTask = Task { await deleteFeed(feedID) }
        case .reportSpoiler(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: true) }
        case .reportImproper(let feedID):
            feedActionTask = Task { await reportFeed(feedID, spoiler: false) }
        case .reportSpoilerCompleted, .reportImproperCompleted:
            break
        }
    }

    /// 평가 삭제 진입(드롭다운). 삭제할 평가가 없으면(미평가·비로그인) 알럿 없이 무시한다 —
    /// 관심 토글의 no-op과 같은 정책.
    func presentDeleteReviewAlert() {
        guard state.information?.userReview != nil,
              deleteReviewTask == nil,
              !isClosing else { return }
        state.isDeleteReviewAlertPresented = true
    }

    /// 알럿에서 삭제 확정.
    func confirmDeleteReview() {
        state.isDeleteReviewAlertPresented = false
        guard deleteReviewTask == nil, !isClosing else { return }
        deleteReviewTask = Task { await deleteReview() }
    }

    /// 뒤로가기 요청. 진행 중인 로드를 취소하고 닫기 신호만 View로 발화한다.
    func close() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        feedsTask?.cancel()
        deleteReviewTask?.cancel()
        feedActionTask?.cancel()
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
            // 인증 만료는 실패 뷰 대신 로그인 유도로 일원화한다(이 catch는 presentError를 안 거치므로 직접 감지).
            if routeToLoginIfAuthenticationRequired(error) { return }
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
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다(loadNovel/loadDraft와 대칭).
            if routeToLoginIfAuthenticationRequired(error) { return }

            // 첫 페이지든 더보기든 **탭 자리를 실패 뷰(재시도 버튼)로 대체**한다 — 사용자에겐 둘 다
            // "피드를 못 불러왔다"는 같은 사건이고, 토스트는 사라지면 다시 부를 방법이 없다.
            // (규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약")
            state.feedsLoadFailed = true
            logger?.error("피드 로드 실패(cursor: \(lastFeedID.map(String.init(describing:)) ?? "첫 페이지")): \(String(describing: error))")
        }
    }

    /// 평가 삭제 후 상세 재로드 — 평가만 지우면 끝이 아니라 키워드·읽기 상태 집계 등
    /// 독자 평가 데이터가 함께 바뀌므로 서버 데이터로 다시 동기화한다.
    /// 기존 화면은 유지한 채 새 데이터가 오면 갈아끼운다(전면 로딩 없음).
    func deleteReview() async {
        defer { deleteReviewTask = nil }
        do {
            try await deleteNovelReviewUseCase.execute(novelID: novelID)
            guard !isClosing, !Task.isCancelled else { return }
            state.presentedToast = .reviewDeleted
            // 재로드가 실패해도 재진입 시 다시 시도되도록 가드를 미리 되돌린다(성공 시 loadNovel이 재소진).
            hasLoaded = false
            await loadNovel()
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: .deleteReviewFailed)
        }
    }

    /// 좋아요 서버 동기화. 실패하면 낙관 반영을 롤백한다.
    /// 롤백 시점엔 페이지네이션 append로 인덱스가 변했을 수 있어 피드를 다시 찾는다.
    func syncFeedLike(to isLiked: Bool, feedID: FeedID, rollbackTo before: TotalFeed) async {
        defer { syncingLikeFeedIDs.remove(feedID) }
        do {
            if isLiked {
                try await feedLikeUseCase.like(feedID: feedID)
            } else {
                try await feedLikeUseCase.unlike(feedID: feedID)
            }
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            if let index = state.feeds.firstIndex(where: { $0.feedId == feedID }) {
                state.feeds[index] = before
            }
            presentError(error, as: .likeFailed)
        }
    }

    /// 피드 삭제. 성공하면 목록에서 즉시 제거하고, 헤더의 피드 수 등 집계가 바뀌므로 상세를 재동기화한다.
    func deleteFeed(_ feedID: FeedID) async {
        defer { feedActionTask = nil }
        do {
            try await deleteFeedUseCase.execute(feedID: feedID)
            guard !isClosing, !Task.isCancelled else { return }
            state.feeds.removeAll { $0.feedId == feedID }
            // 평가 삭제와 같은 이유의 재로드 — 실패해도 재진입 시 다시 시도되도록 가드를 미리 되돌린다.
            hasLoaded = false
            await loadNovel()
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: .deleteFeedFailed)
        }
    }

    /// 피드 신고. 성공하면 접수 완료 알럿으로 전환한다(신고는 목록에 보이는 변화가 없다).
    func reportFeed(_ feedID: FeedID, spoiler: Bool) async {
        defer { feedActionTask = nil }
        do {
            if spoiler {
                try await reportSpoilerFeedUseCase.execute(id: feedID)
            } else {
                try await reportImproperFeedUseCase.execute(id: feedID)
            }
            guard !isClosing, !Task.isCancelled else { return }
            state.presentedFeedAlert = spoiler ? .reportSpoilerCompleted : .reportImproperCompleted
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, as: .reportFeedFailed)
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

    /// Repository 에러를 발생 맥락의 의미 토스트로 변환한다. 원인은 로그로 남긴다.
    /// (`handle(_:)`과 이름이 겹치지 않게 분리)
    func presentError(_ error: Error, as presented: DetailToast) {
        // 인증 만료면 개별 실패 토스트 대신 로그인 유도로 일원화한다(피드/좋아요/삭제/신고/관심 공통 경로).
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("NovelDetail 실패(\(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 개별 실패 토스트 대신 로그인 유도로 일원화한다.
    /// (`RepositoryError`는 `Equatable` — 여기서 쓰는 건 import된 `BaseDomain.RepositoryError`다.)
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
