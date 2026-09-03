//
//  SosoFeedViewModel.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import FeedDomain
import ProfileDomain
import SocialDomain
import Logger

enum FeedTab {
    case myFeed
    case sosoFeed
}

@Observable
@MainActor
final class SosoFeedViewModel {

    //MARK: - State

    struct State {
        var selectedTab: FeedTab = .myFeed
        var selectedSosoFeedOption: SosoFeedOption = .all

        var myFeeds: [TotalFeed] = []
        var sosoFeeds: [TotalFeed] = []

        /// 내 피드 전체 개수(서버 `feedsCount`). "n개의 기록" 표시에 로드된 배열 길이 대신 쓴다 —
        /// 페이지네이션 전엔 배열이 최대 20까지라 실제 총량과 어긋나기 때문(V1 parity, #222). 로드 전엔 nil.
        var myFeedsTotalCount: Int?

        /// 실제 fetch에 사용되는 커밋된 필터.
        var myFeedOption: MyFeedOption = MyFeedOption(
            genres: NovelGenre.allCases,
            includesUncategorized: true,
            visibilityType: .all,
            sortType: .recent
        )

        /// 필터 시트가 편집하는 임시 버퍼. CTA로 commit 되기 전까지 fetch에 영향 없음.
        var myFeedOptionDraft: MyFeedOption = MyFeedOption(
            genres: NovelGenre.allCases,
            includesUncategorized: true,
            visibilityType: .all,
            sortType: .recent
        )

        var hasMoreMyFeeds: Bool = true
        var hasMoreSosoFeeds: Bool = true

        /// 처음부터 다시 채우는 로드(`LoadKind.reload`)가 도는 중. View는 보여줄 목록이 없을 때만 로딩 뷰로 쓴다.
        var isLoading: Bool = false
        var errorMessage: String?

        /// 작성 완료로 목록을 처음부터 다시 채울 때 +1 — View가 `scrollIdentity`에 합쳐 ScrollView를 새 뷰로
        /// 취급하게(스크롤 최상단, 새 글이 맨 위) 한다. 탭/옵션/필터 전환은 그 값 자체가 `scrollIdentity`에
        /// 들어 있어 이 카운터가 필요 없다.
        var listGeneration = 0

        /// 피드 셀 액션(삭제/신고)의 확인·완료 알럿 — 확정 시 실행할 대상 피드를 함께 보관한다.
        var presentedFeedAlert: FeedAlert?
        /// 프로필 탭이 탈퇴 유저(`Author.userId == -1`)를 가리킬 때 뜨는 안내 토스트
        /// (`WSSToastType.unknownUser`) — `UserPageViewModel.isNoCollectionsToastPresented`와 동일 패턴.
        var isUnavailableUserToastPresented = false
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

    enum Action {
        case selectTab(FeedTab)
        case selectSosoFeedOption(SosoFeedOption)
        /// 진입/재진입(onAppear). 첫 진입은 첫 페이지 로드, 재진입은 **목록 재조회 없이** 다녀온 셀만 동기화.
        case load
        case loadMore
        /// 당겨서 새로고침 — 현재 탭을 처음부터 다시 받는다(전체 최신화는 이 경로뿐).
        case pullToRefresh
        /// 피드 작성 완료(App 신호) — 현재 탭을 처음부터 다시 받고 스크롤을 최상단으로(새 글이 맨 위).
        case reloadForCreatedFeed
        /// View가 이 피드로 화면을 떠나기(셀 탭 → 상세, "수정하기" → 수정) 직전에 부른다 — 돌아오면 그 셀만
        /// 상세 API로 맞춘다.
        case feedVisited(FeedID)
        case toggleLike(FeedID)
        case toggleMyFeedSort

        // 필터 시트
        case resetMyFeedFilterDraft
        case toggleMyFeedFilterGenre(NovelGenre)
        case toggleMyFeedFilterEtc
        case toggleMyFeedFilterPublic
        case toggleMyFeedFilterPrivate
        case applyMyFeedFilter

        // 피드 셀 threedots 드롭다운
        case deleteFeedTapped(FeedID)
        case reportSpoilerFeedTapped(FeedID)
        case reportImproperFeedTapped(FeedID)
        case confirmFeedAlert
        case dismissFeedAlert

        /// View가 `feed.author.accessibleUserId == nil`(탈퇴 유저)로 판정해서 부른다 — 화면 전환
        /// 콜백 대신 여기서 그친다.
        case userProfileUnavailableTapped
        case dismissUnavailableUserToast
    }

    //MARK: - Filter Selection Helpers

    var isMyFeedFilterPublicSelected: Bool {
        state.myFeedOptionDraft.visibilityType != .privateOnly
    }

    var isMyFeedFilterPrivateSelected: Bool {
        state.myFeedOptionDraft.visibilityType != .publicOnly
    }

    func isMyFeedFilterGenreSelected(_ genre: NovelGenre) -> Bool {
        state.myFeedOptionDraft.genres.contains(genre)
    }

    var isMyFeedFilterEtcSelected: Bool {
        state.myFeedOptionDraft.includesUncategorized
    }

    // MARK: - Properties

    private(set) var state: State

    private let loadMyFeedsUseCase: LoadMyFeedsUseCase
    private let loadSosoFeedsUseCase: LoadSosoFeedsUseCase
    /// 다녀온 셀 동기화용(`syncVisitedFeeds`) — 목록 API가 아니라 피드 상세 API로 그 셀 하나만 다시 받는다.
    private let loadFeedDetailUseCase: LoadFeedDetailUseCase
    private let feedLikeUseCase: FeedLikeUseCase
    private let loadProfileUseCase: LoadProfileUseCase
    private let deleteFeedUseCase: DeleteFeedUseCase
    private let reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase
    private let reportImproperFeedUseCase: ReportImproperFeedUseCase
    private let logger: Logger?

    /// "내 피드" 목록 API가 작성자 정보(닉네임/프로필 이미지)를 내려주지 않아, 별도로 받아온 내 프로필로 채워 넣는다.
    /// 탭을 오갈 때마다 다시 조회하지 않도록 캐시한다.
    private var cachedMyProfile: Profile?

    /// 목록 로드의 성격 — 시작 표시·커서·반영이 전부 여기서 갈린다(서재 `LoadKind`와 같은 형태).
    private enum LoadKind {
        /// 처음부터(커서 0) 다시 채워 **교체** — 첫 진입·탭/옵션/필터/정렬 전환·당겨서 새로고침·작성 완료.
        case reload(FeedTab)
        /// 다음 페이지를 **이어붙임** — 마지막 셀 onAppear.
        case more(FeedTab)
    }

    /// 목록 로드(첫 페이지·더보기)는 **이 한 슬롯**에만 산다. 시작하는 모든 경로는 `nil`을 확인하거나
    /// (`load`/`loadMore`), 이전 로드를 취소하고 곧바로 재대입한다(`reloadFromScratch`) — 그래서 늦게 도착한
    /// 옛 결과는 세대 카운터 없이 `Task.isCancelled`만으로 걸러진다(서재 `LibraryViewModel.loadPage` 불변식).
    @ObservationIgnored private var feedsTask: Task<Void, Never>?
    /// 다녀온 셀 동기화 Task — 목록 로드와 별개 슬롯(셀 하나를 ID로 교체할 뿐이라 목록 로드와 겹쳐도 무해).
    @ObservationIgnored private var cellSyncTask: Task<Void, Never>?
    /// 화면을 떠나며 들어간 피드들 — 복귀 `.load`에서 꺼내 상세로 동기화한다.
    @ObservationIgnored private var pendingSyncFeedIDs: Set<FeedID> = []
    /// 탭별 "첫 페이지를 한 번이라도 성공적으로 세웠는지" — 재진입 `.load`가 첫 로드인지 동기화인지 가르는 기준.
    /// ⚠️ `state.myFeeds.isEmpty`로 대체하면 안 된다 — 피드 0건 유저는 성공해도 배열이 비어 복귀마다 로딩 뷰로 깜빡인다.
    @ObservationIgnored private var hasLoadedMyFeeds = false
    @ObservationIgnored private var hasLoadedSosoFeeds = false
    /// 좋아요 서버 동기화가 진행 중인 셀 — 같은 셀 연타 가드 + 목록 교체/셀 동기화가 낙관 토글을 되덮지 않게 보호.
    @ObservationIgnored private var syncingLikeFeedIDs: Set<FeedID> = []
    /// 마지막 `.reload` 요청 이후 토글한 셀 — 요청이 도는 동안 눌린 좋아요는 응답 스냅샷에 없을 수 있어 병합 보호
    /// 대상에 합친다(`NovelDetailViewModel.likeToggledDuringRefresh`와 동일).
    @ObservationIgnored private var likeToggledDuringReload: Set<FeedID> = []

    /// 피드 삭제/신고는 한 번에 하나만 — 알럿을 거치므로 동시에 두 개가 뜰 일이 없다.
    @ObservationIgnored private var feedActionTask: Task<Void, Never>?

    init(
        loadMyFeedsUseCase: LoadMyFeedsUseCase,
        loadsosoFeedsUseCase: LoadSosoFeedsUseCase,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadProfileUseCase: LoadProfileUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) {
        self.state = State()

        self.loadMyFeedsUseCase = loadMyFeedsUseCase
        self.loadSosoFeedsUseCase = loadsosoFeedsUseCase
        self.loadFeedDetailUseCase = loadFeedDetailUseCase
        self.feedLikeUseCase = feedLikeUseCase
        self.loadProfileUseCase = loadProfileUseCase
        self.deleteFeedUseCase = deleteFeedUseCase
        self.reportSpoilerFeedUseCase = reportSpoilerFeedUseCase
        self.reportImproperFeedUseCase = reportImproperFeedUseCase
        self.logger = logger
    }

    //MARK: - Handle

    func handle(_ action: Action) {
        switch action {
        case .selectTab(let tab):
            selectTab(tab)
        case .selectSosoFeedOption(let option):
            selectSosoFeedOption(option)
        case .load:
            load()
        case .loadMore:
            loadMore()
        case .pullToRefresh:
            reloadFromScratch(state.selectedTab)
        case .reloadForCreatedFeed:
            state.listGeneration += 1
            reloadFromScratch(state.selectedTab)
        case .feedVisited(let feedID):
            pendingSyncFeedIDs.insert(feedID)
        case .toggleLike(let feedID):
            toggleLike(feedID)
        case .toggleMyFeedSort:
            toggleMyFeedSort()

        case .resetMyFeedFilterDraft:
            state.myFeedOptionDraft = state.myFeedOption
        case .toggleMyFeedFilterGenre(let genre):
            toggleMyFeedFilterGenre(genre)
        case .toggleMyFeedFilterEtc:
            toggleMyFeedFilterEtc()
        case .toggleMyFeedFilterPublic:
            toggleMyFeedFilterVisibility(togglingPublic: true)
        case .toggleMyFeedFilterPrivate:
            toggleMyFeedFilterVisibility(togglingPublic: false)
        case .applyMyFeedFilter:
            applyMyFeedFilter()

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

        case .userProfileUnavailableTapped:
            state.isUnavailableUserToastPresented = true
        case .dismissUnavailableUserToast:
            state.isUnavailableUserToastPresented = false
        }
    }

    /// 당겨서 새로고침 인디케이터가 로드 완료까지 남게 하는 대기 — 입력이 아니라 진행 중 로드의 종료 관찰이라
    /// `handle` 밖에 둔다. 가드에 막혀 새 로드를 못 띄웠어도 진행 중인 그 로드를 기다린다.
    func awaitFeedsLoad() async {
        await feedsTask?.value
    }

    //MARK: - Tab / Option

    /// 같은 탭 재탭은 무시한다 — 처음부터 다시 받으면 목록이 첫 페이지로 줄어 스크롤이 튄다.
    private func selectTab(_ tab: FeedTab) {
        guard tab != state.selectedTab else { return }
        state.selectedTab = tab
        reloadFromScratch(tab)
    }

    private func selectSosoFeedOption(_ option: SosoFeedOption) {
        guard option != state.selectedSosoFeedOption else { return }
        state.selectedSosoFeedOption = option
        logger?.info("소소피드 옵션: \(option)")
        guard state.selectedTab == .sosoFeed else { return }
        reloadFromScratch(.sosoFeed)
    }

    //MARK: - Load

    /// 진입/재진입 로드(onAppear는 재진입마다 불린다). 현재 탭의 첫 페이지를 아직 못 세웠으면 첫 로드,
    /// 세웠으면 **목록을 다시 받지 않고** 다녀온 셀만 상세로 맞춘다 — 목록을 다시 받으면 20개로 줄어 스크롤이
    /// 튀기 때문. 전체 최신화는 당겨서 새로고침이 맡는다(탭 콘텐츠 "복귀마다 갱신" 규약의 의도된 예외).
    private func load() {
        guard feedsTask == nil else { return }
        if hasLoaded(state.selectedTab) {
            syncVisitedFeeds()
        } else {
            reloadFromScratch(state.selectedTab)
        }
    }

    /// 현재 탭의 다음 페이지를 이어붙인다. 진행 중인 로드가 있으면 드롭된다(재로드 중 바닥 도달 등 — 셀 재실현으로 복구).
    private func loadMore() {
        let tab = state.selectedTab
        guard feedsTask == nil, hasLoaded(tab), hasMore(tab) else { return }
        feedsTask = Task { await loadFeeds(.more(tab)) }
    }

    /// 처음부터 다시 채운다 — 진행 중이던 이전 로드를 **취소하고 곧바로 재대입**한다(취소만 하고 재대입하지 않는
    /// 경로를 만들면 슬롯이 non-nil로 굳어 `load`가 영구 차단된다). 다녀온 셀 동기화도 무의미해지므로 함께 버린다.
    /// 시작 표시(`isLoading`)는 Task 스폰 **전** 동기 구간에서 세운다 — 취소된 옛 로드는 아무것도 정리하지
    /// 않으므로(`loadFeeds`의 defer) 새 로드의 표시를 지우지 못한다.
    private func reloadFromScratch(_ tab: FeedTab) {
        feedsTask?.cancel()
        cellSyncTask?.cancel()
        cellSyncTask = nil
        pendingSyncFeedIDs = []
        setHasLoaded(false, for: tab)
        state.isLoading = true
        feedsTask = Task { await loadFeeds(.reload(tab)) }
    }

    /// 목록 로드 본체 — 조회는 `kind`가 정하고, 반영은 취소 확인 뒤 한 곳에서 한다.
    ///
    /// 취소된 로드는 **아무것도 정리하지 않는다** — 정리하면 자기를 밀어낸 새 로드의 `feedsTask`와 로딩 표시를
    /// 지운다(defer 안에서는 `return`이 안 돼 `if`로 감싼다). ⚠️ 취소는 `CancellationError`가 아니라
    /// `RepositoryError.networkUnavailable`로 도착한다(`URLError.cancelled` → `NetworkingError.unknown` →
    /// `.networkUnavailable`) — 그래서 실패 경로도 첫 줄에서 취소를 걸러야 옛 로드가 에러를 세우지 않는다.
    private func loadFeeds(_ kind: LoadKind) async {
        guard !Task.isCancelled else { return }
        defer {
            if !Task.isCancelled {
                feedsTask = nil
                state.isLoading = false
            }
        }
        if case .reload = kind { likeToggledDuringReload = [] }
        do {
            let page = try await fetchPage(kind)
            guard !Task.isCancelled else { return }
            apply(page, kind: kind)
        } catch {
            guard !Task.isCancelled else { return }
            switch kind {
            case .reload(.myFeed), .more(.myFeed):
                state.errorMessage = "내 피드를 불러오지 못했어요."
            case .reload(.sosoFeed), .more(.sosoFeed):
                state.errorMessage = "소소피드를 불러오지 못했어요."
            }
            logger?.error("피드 목록 로드 실패(\(kind)): \(String(describing: error))")
        }
    }

    /// 네트워크만 수행하고 **상태는 건드리지 않는다**. 필터·옵션은 요청 직전에 한 번만 읽는다 — 프로필 조회 뒤에
    /// 다시 읽으면 그 사이 바뀐 필터와 옛 커서가 뒤섞인 요청이 나간다(결과는 취소 가드가 버리지만 요청은 서버에 닿는다).
    private func fetchPage(_ kind: LoadKind) async throws(RepositoryError) -> Paginated<TotalFeed> {
        switch kind {
        case .reload(.myFeed):
            return try await fetchMyFeeds(option: state.myFeedOption, after: FeedID(0))
        case .more(.myFeed):
            return try await fetchMyFeeds(option: state.myFeedOption, after: state.myFeeds.last?.feedId ?? FeedID(0))
        case .reload(.sosoFeed):
            return try await loadSosoFeedsUseCase.execute(option: state.selectedSosoFeedOption, lastFeedID: FeedID(0))
        case .more(.sosoFeed):
            return try await loadSosoFeedsUseCase.execute(
                option: state.selectedSosoFeedOption,
                lastFeedID: state.sosoFeeds.last?.feedId ?? FeedID(0)
            )
        }
    }

    private func fetchMyFeeds(option: MyFeedOption, after cursor: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let profile = try await myProfile()
        let page = try await loadMyFeedsUseCase.execute(option: option, lastFeedID: cursor)
        return Paginated(
            items: page.items.map { applying(profile, to: $0) },
            hasNext: page.hasNext,
            totalCount: page.totalCount
        )
    }

    private func apply(_ page: Paginated<TotalFeed>, kind: LoadKind) {
        switch kind {
        case .reload(.myFeed):
            state.myFeeds = preservingSyncingLikes(in: page.items, from: state.myFeeds)
            state.hasMoreMyFeeds = page.hasNext
            state.myFeedsTotalCount = page.totalCount
            hasLoadedMyFeeds = true
        case .more(.myFeed):
            state.myFeeds += page.items
            state.hasMoreMyFeeds = page.hasNext
            state.myFeedsTotalCount = page.totalCount
        case .reload(.sosoFeed):
            state.sosoFeeds = preservingSyncingLikes(in: page.items, from: state.sosoFeeds)
            state.hasMoreSosoFeeds = page.hasNext
            hasLoadedSosoFeeds = true
        case .more(.sosoFeed):
            state.sosoFeeds += page.items
            state.hasMoreSosoFeeds = page.hasNext
        }
    }

    /// 목록 교체가 진행 중인 낙관 좋아요를 되덮지 않게 병합한다 — 보호 대상은 "요청 시작 시 in-flight" ∪
    /// "요청이 도는 동안 토글"(둘 다 서버 응답이 토글 이전 스냅샷일 수 있다). 보호 셀은 **좋아요 두 필드만**
    /// 로컬 우선(`preservingLikeState`) — 셀 전체를 로컬로 되돌리면 그 사이 서버에서 바뀐 본문·댓글수까지 버린다.
    private func preservingSyncingLikes(in items: [TotalFeed], from locals: [TotalFeed]) -> [TotalFeed] {
        let protectedIDs = syncingLikeFeedIDs.union(likeToggledDuringReload)
        guard !protectedIDs.isEmpty else { return items }
        return items.map { item in
            guard protectedIDs.contains(item.feedId),
                  let local = locals.first(where: { $0.feedId == item.feedId }) else { return item }
            return item.preservingLikeState(of: local)
        }
    }

    private func hasLoaded(_ tab: FeedTab) -> Bool {
        switch tab {
        case .myFeed: hasLoadedMyFeeds
        case .sosoFeed: hasLoadedSosoFeeds
        }
    }

    private func setHasLoaded(_ value: Bool, for tab: FeedTab) {
        switch tab {
        case .myFeed: hasLoadedMyFeeds = value
        case .sosoFeed: hasLoadedSosoFeeds = value
        }
    }

    private func hasMore(_ tab: FeedTab) -> Bool {
        switch tab {
        case .myFeed: state.hasMoreMyFeeds
        case .sosoFeed: state.hasMoreSosoFeeds
        }
    }

    /// 캐시된 내 프로필이 있으면 재사용하고, 없으면 조회해 캐시한다.
    private func myProfile() async throws(RepositoryError) -> Profile {
        if let cachedMyProfile { return cachedMyProfile }
        let profile = try await loadProfileUseCase.execute(target: .me)
        cachedMyProfile = profile
        return profile
    }

    /// `fetchMyFeeds` 응답엔 작성자 닉네임/프로필 이미지가 없어(FeedData 쪽 DTO 자체가 안 내려줌),
    /// 별도로 받아온 내 프로필 정보로 채워 넣는다. userId는 이미 올바르게 채워져 있으므로 유지한다.
    private func applying(_ profile: Profile, to feed: TotalFeed) -> TotalFeed {
        TotalFeed(
            feedId: feed.feedId,
            createdDate: feed.createdDate,
            content: feed.content,
            author: Author(
                userId: feed.author.userId,
                nickname: profile.nickname,
                profileImage: profile.characterImage
            ),
            likeCount: feed.likeCount,
            isLiked: feed.isLiked,
            commentCount: feed.commentCount,
            connectedNovel: feed.connectedNovel,
            isSpoiler: feed.isSpoiler,
            isModified: feed.isModified,
            isPublic: feed.isPublic,
            isMyFeed: feed.isMyFeed,
            thumbnailImageURL: feed.thumbnailImageURL,
            imageCount: feed.imageCount
        )
    }

    //MARK: - Cell Sync

    /// 목록에서 다녀온 피드(셀 탭 → 상세, "수정하기" → 수정)만 상세 API로 맞춘다 — 재진입 목록 재조회의 대체.
    /// 로딩·토스트 없이 그 셀만 교체하고, 상세가 `.notFound`/`.forbidden`(삭제·숨김·차단 —
    /// `FeedDetailViewModel.isFeedUnavailable`와 같은 판정)이면 셀을 제거한다. 그 외 실패는 셀을 그대로 둔다
    /// (잘못 지우는 것보다 낫고, 당겨서 새로고침으로 복구된다).
    /// 이전 동기화가 아직 도는 중이면 pending은 다음 복귀까지 남는다(보통 셀 하나라 수백 ms).
    private func syncVisitedFeeds() {
        guard cellSyncTask == nil, !pendingSyncFeedIDs.isEmpty else { return }
        let feedIDs = pendingSyncFeedIDs
        pendingSyncFeedIDs = []
        cellSyncTask = Task {
            defer { if !Task.isCancelled { cellSyncTask = nil } }
            for feedID in feedIDs {
                await syncCell(feedID)
                if Task.isCancelled { return }
            }
        }
    }

    private func syncCell(_ feedID: FeedID) async {
        do {
            let detail = try await loadFeedDetailUseCase.execute(feedID: feedID)
            guard !Task.isCancelled else { return }
            replaceCell(feedID) { local in
                let updated = local.updated(from: detail)
                // 좋아요 서버 동기화가 아직 도는 셀은 상세 응답이 토글 이전 스냅샷일 수 있다 — 좋아요 두 필드만 로컬 우선.
                return syncingLikeFeedIDs.contains(feedID) ? updated.preservingLikeState(of: local) : updated
            }
        } catch {
            guard !Task.isCancelled else { return }
            if error == .notFound || error == .forbidden {
                removeCell(feedID)
            } else {
                logger?.error("피드 셀 동기화 실패(\(feedID.value)): \(String(describing: error))")
            }
        }
    }

    /// 두 목록(내 피드/소소피드) 모두에서 해당 피드를 찾아 교체한다 — 내 글은 소소피드에도 섞여 나올 수 있다.
    private func replaceCell(_ feedID: FeedID, with transform: (TotalFeed) -> TotalFeed) {
        if let index = state.myFeeds.firstIndex(where: { $0.feedId == feedID }) {
            state.myFeeds[index] = transform(state.myFeeds[index])
        }
        if let index = state.sosoFeeds.firstIndex(where: { $0.feedId == feedID }) {
            state.sosoFeeds[index] = transform(state.sosoFeeds[index])
        }
    }

    private func removeCell(_ feedID: FeedID) {
        state.myFeeds.removeAll { $0.feedId == feedID }
        state.sosoFeeds.removeAll { $0.feedId == feedID }
    }

    //MARK: - Sort

    private func toggleMyFeedSort() {
        let draft = state.myFeedOption
        let nextSortType: SortType = draft.sortType == .recent ? .old : .recent

        state.myFeedOption = MyFeedOption(
            genres: draft.genres,
            includesUncategorized: draft.includesUncategorized,
            visibilityType: draft.visibilityType,
            sortType: nextSortType
        )
        logger?.info("내 피드 정렬: \(nextSortType)")
        reloadFromScratch(.myFeed)
    }

    //MARK: - Like

    /// 낙관적 업데이트: 먼저 엔티티의 toggleLike()로 즉시 UI 반영(두 목록 모두), 서버 호출이 실패하면
    /// 스냅샷의 좋아요 두 필드만 되돌린다 — "같은 토글을 다시 실행"하는 방식은 그 사이 목록 교체/셀 동기화가
    /// 끼어들면 서버 새 값 위에 이중 토글이 걸린다. 같은 셀은 서버 동기화가 끝날 때까지 연타를 무시한다.
    private func toggleLike(_ feedID: FeedID) {
        guard !syncingLikeFeedIDs.contains(feedID) else { return }
        let beforeMy = state.myFeeds.first { $0.feedId == feedID }
        let beforeSoso = state.sosoFeeds.first { $0.feedId == feedID }
        guard let before = beforeMy ?? beforeSoso else { return }
        var toggled = before
        guard (try? toggled.toggleLike()) != nil else { return }

        replaceCell(feedID) { local in
            var copy = local
            try? copy.toggleLike()
            return copy
        }
        syncingLikeFeedIDs.insert(feedID)
        likeToggledDuringReload.insert(feedID)
        Task { await syncFeedLike(to: toggled.isLiked, feedID: feedID, rollbackTo: (beforeMy, beforeSoso)) }
    }

    private func syncFeedLike(
        to isLiked: Bool,
        feedID: FeedID,
        rollbackTo before: (my: TotalFeed?, soso: TotalFeed?)
    ) async {
        defer { syncingLikeFeedIDs.remove(feedID) }
        do {
            if isLiked {
                try await feedLikeUseCase.like(feedID: feedID)
            } else {
                try await feedLikeUseCase.unlike(feedID: feedID)
            }
        } catch {
            // 좋아요 두 필드만 되돌림 — 그 사이 셀 동기화가 가져온 최신 본문을 이전 스냅샷으로 물리지 않게(병합과 대칭).
            if let beforeMy = before.my,
               let index = state.myFeeds.firstIndex(where: { $0.feedId == feedID }) {
                state.myFeeds[index] = state.myFeeds[index].preservingLikeState(of: beforeMy)
            }
            if let beforeSoso = before.soso,
               let index = state.sosoFeeds.firstIndex(where: { $0.feedId == feedID }) {
                state.sosoFeeds[index] = state.sosoFeeds[index].preservingLikeState(of: beforeSoso)
            }
            state.errorMessage = "좋아요 처리에 실패했어요."
            logger?.error("피드 좋아요 동기화 실패(\(feedID.value)): \(String(describing: error))")
        }
    }

    //MARK: - Filter Draft

    /// 필터 시트의 draft를 실제 fetch에 쓰는 커밋된 필터로 반영하고 재조회한다.
    private func applyMyFeedFilter() {
        state.myFeedOption = state.myFeedOptionDraft
        logger?.info("\(state.myFeedOption.genres.map { $0.displayName }), \(state.myFeedOption.visibilityType)")
        reloadFromScratch(.myFeed)
    }

    private func toggleMyFeedFilterGenre(_ genre: NovelGenre) {
        let draft = state.myFeedOptionDraft
        let newGenres: [NovelGenre] = draft.genres.contains(genre)
            ? draft.genres.filter { $0 != genre }
            : draft.genres + [genre]

        state.myFeedOptionDraft = MyFeedOption(
            genres: newGenres,
            includesUncategorized: draft.includesUncategorized,
            visibilityType: draft.visibilityType,
            sortType: draft.sortType
        )
    }

    /// "기타"(연결 작품 없는 피드) 칩 토글.
    private func toggleMyFeedFilterEtc() {
        let draft = state.myFeedOptionDraft
        state.myFeedOptionDraft = MyFeedOption(
            genres: draft.genres,
            includesUncategorized: !draft.includesUncategorized,
            visibilityType: draft.visibilityType,
            sortType: draft.sortType
        )
    }

    /// 공개/비공개 체크박스는 독립 토글이지만 둘 다 해제되는 상태는 허용하지 않는다(무시).
    private func toggleMyFeedFilterVisibility(togglingPublic: Bool) {
        let draft = state.myFeedOptionDraft
        var includesPublic = draft.visibilityType != .privateOnly
        var includesPrivate = draft.visibilityType != .publicOnly

        if togglingPublic {
            includesPublic.toggle()
        } else {
            includesPrivate.toggle()
        }

        guard includesPublic || includesPrivate else { return }

        let nextVisibility: VisibilityType
        if includesPublic, includesPrivate {
            nextVisibility = .all
        } else if includesPublic {
            nextVisibility = .publicOnly
        } else {
            nextVisibility = .privateOnly
        }

        state.myFeedOptionDraft = MyFeedOption(
            genres: draft.genres,
            includesUncategorized: draft.includesUncategorized,
            visibilityType: nextVisibility,
            sortType: draft.sortType
        )
    }

    //MARK: - Feed Menu

    /// 피드 삭제/신고 확인 알럿 표시. 진행 중인 액션이 있으면 무시한다.
    private func presentFeedAlert(_ alert: FeedAlert) {
        guard feedActionTask == nil else { return }
        state.presentedFeedAlert = alert
    }

    /// 알럿에서 확정. 접수 완료 알럿(1버튼)의 "확인"은 dismiss로만 들어오므로 여기 오지 않는다.
    private func confirmFeedAlert() {
        guard let alert = state.presentedFeedAlert else { return }
        state.presentedFeedAlert = nil
        guard feedActionTask == nil else { return }
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

    /// 피드 삭제. 성공하면 두 목록(내 피드/소소피드) 중 해당 피드가 있는 쪽에서 제거한다.
    /// 다녀온 셀 대기열에서도 빼 지운 셀을 상세로 되살리려 들지 않게 한다(상세는 어차피 `.notFound`지만 요청 낭비).
    private func deleteFeed(_ feedID: FeedID) async {
        defer { feedActionTask = nil }
        do {
            try await deleteFeedUseCase.execute(feedID: feedID)
            pendingSyncFeedIDs.remove(feedID)
            removeCell(feedID)
        } catch {
            state.errorMessage = "피드 삭제에 실패했어요."
        }
    }

    /// 피드 신고. 성공하면 접수 완료 알럿으로 전환한다(신고는 목록에 보이는 변화가 없다).
    private func reportFeed(_ feedID: FeedID, spoiler: Bool) async {
        defer { feedActionTask = nil }
        do {
            if spoiler {
                try await reportSpoilerFeedUseCase.execute(id: feedID)
            } else {
                try await reportImproperFeedUseCase.execute(id: feedID)
            }
            state.presentedFeedAlert = spoiler ? .reportSpoilerCompleted : .reportImproperCompleted
        } catch {
            state.errorMessage = "신고 접수에 실패했어요."
        }
    }
}
