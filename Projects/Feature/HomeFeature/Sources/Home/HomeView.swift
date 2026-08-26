//
//  HomeView.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import RecommendationDomain
import NotificationDomain
import PushAuthorization
import DesignSystem
import WSSComponent

/// 홈 탭 콘텐츠. 추천 3종을 한 화면에 모아 보여주고, 선택 결과는 전부 상위로 위임한다.
/// "얇은 VM": 카피·포맷·색은 전부 이 View가 결정한다.
struct HomeView: View {

    @State private var viewModel: HomeViewModel
    /// "설정하러 가기" 탭 시 iOS 설정 앱의 **이 앱 알림 설정 페이지**로 바로 여는 데 쓴다 — VM은
    /// "권한이 denied라 알럿을 띄워야 한다"는 판단만 갖고, 시스템 앱을 여는 행위 자체는 View가 수행한다
    /// (SettingFeature와 동일).
    @Environment(\.openURL) private var openURL
    private let onNovelSelected: (NovelID) -> Void
    private let onFeedSelected: (FeedID) -> Void
    private let onSearchTapped: () -> Void
    private let onDetailSearchTapped: () -> Void
    private let onNotificationTapped: () -> Void
    private let onPreferenceGenreSettingTapped: () -> Void
    private let onAuthenticationRequired: () -> Void

    private enum Metric {
        static let searchToDiscovery: CGFloat = 24
        static let discoveryToTrending: CGFloat = 32
        static let trendingToPreference: CGFloat = 38
        static let bottomInset: CGFloat = 40

        static let sectionTitleSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 10
    }

    init(
        viewModel: HomeViewModel,
        onNovelSelected: @escaping (NovelID) -> Void,
        onFeedSelected: @escaping (FeedID) -> Void,
        onSearchTapped: @escaping () -> Void,
        onDetailSearchTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void,
        onPreferenceGenreSettingTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelSelected = onNovelSelected
        self.onFeedSelected = onFeedSelected
        self.onSearchTapped = onSearchTapped
        self.onDetailSearchTapped = onDetailSearchTapped
        self.onNotificationTapped = onNotificationTapped
        self.onPreferenceGenreSettingTapped = onPreferenceGenreSettingTapped
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .onAppear {
                viewModel.handle(.load)
                viewModel.handle(.checkPushAuthorizationOnEntry)
            }
            .onChange(of: viewModel.state.requiresAuthentication) { _, requiresAuthentication in
                guard requiresAuthentication else { return }
                // 홈은 탭 콘텐츠라 VM이 앱 세션 내내 산다 → 신호를 소진해야 2회차 만료가 삼켜지지 않는다.
                viewModel.handle(.consumeAuthenticationRequired)
                onAuthenticationRequired()
            }
            .onChange(of: viewModel.state.shouldNavigateToNotifications) { _, shouldNavigate in
                guard shouldNavigate else { return }
                viewModel.handle(.consumeNotificationNavigation)
                onNotificationTapped()
            }
            .showWSSAlert(
                isPresented: pushAuthorizationAlertBinding,
                type: .setAppNotification,
                buttonActions: [
                    { viewModel.handle(.dismissPushAuthorizationAlert) },  // "다음에 하기"
                    {
                        viewModel.handle(.dismissPushAuthorizationAlert)
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }  // "설정하러 가기"
                ]
            )
    }

    /// 헤더만 고정이고 그 아래가 통째로 스크롤/로딩/실패로 갈린다(구 WSSiOS와 같은 경계).
    private var content: some View {
        VStack(spacing: 0) {
            HomeHeaderView(
                hasUnreadNotifications: viewModel.state.hasUnreadNotifications,
                onNotificationTapped: { viewModel.handle(.notificationBellTapped) }
            )

            content(for: viewModel.state)
        }
        .background(Color.wssWhite)
    }

    /// ⚠️ **로딩보다 콘텐츠가 우선**이다 — 홈은 탭 복귀마다 다시 로드하므로, 이미 받아둔 화면까지
    /// 매번 로딩 뷰로 갈아치우면 돌아올 때마다 홈이 통째로 깜빡이고 `ScrollView` 정체성이 바뀌어
    /// 스크롤 위치·추천글 페이지가 초기화된다. 전면 로딩은 **아직 보여줄 게 없을 때만**
    /// (`isInitialLoading`) 띄운다. NovelDetail도 같은 이유로 데이터 우선 분기다.
    @ViewBuilder
    private func content(for state: HomeViewModel.State) -> some View {
        if state.loadFailed {
            NetworkErrorView { viewModel.handle(.load) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.isInitialLoading {
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            recommendationScroll(state)
        }
    }
}

// MARK: - Sections

private extension HomeView {

    func recommendationScroll(_ state: HomeViewModel.State) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HomeSearchSection(
                    onSearchTapped: onSearchTapped,
                    onDetailSearchTapped: onDetailSearchTapped
                )

                // 섹션은 값이 없으면 제목까지 통째로 사라진다 — 아래 섹션이 그만큼 올라붙는다.
                if !state.todayDiscoveries.isEmpty {
                    Spacer().frame(height: Metric.searchToDiscovery)
                    todayDiscoverySection(state.todayDiscoveries)
                }

                if !state.trendingFeeds.isEmpty {
                    Spacer().frame(height: Metric.discoveryToTrending)
                    TrendingFeedSection(
                        nickname: state.nickname,
                        feeds: state.trendingFeeds,
                        onFeedSelected: onFeedSelected
                    )
                }

                if let preferenceGenreNovelState = state.preferenceGenreNovelState,
                   !isEmptyNovels(preferenceGenreNovelState) {
                    Spacer().frame(height: Metric.trendingToPreference)
                    PreferenceGenreSection(
                        state: preferenceGenreNovelState,
                        onNovelSelected: onNovelSelected,
                        onSettingTapped: onPreferenceGenreSettingTapped
                    )
                }

                Spacer().frame(height: Metric.bottomInset)
            }
        }
    }

    func todayDiscoverySection(_ discoveries: [TodayDiscovery]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("+ 오늘의 발견 +")
                    .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal, Metric.horizontalPadding)

            Spacer().frame(height: Metric.sectionTitleSpacing)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Metric.cardSpacing) {
                    ForEach(discoveries, id: \.novelID) { discovery in
                        TodayDiscoveryCard(discovery: discovery) {
                            onNovelSelected(discovery.novelID)
                        }
                    }
                }
                .padding(.horizontal, Metric.horizontalPadding)
            }
        }
    }
}

// MARK: - Presentation

private extension HomeView {

    /// 선호장르 **미설정**은 빈 상태가 아니라 설정 유도 카드를 띄우는 분기라, 숨김 대상은
    /// "설정은 했는데 추천이 0건"인 경우뿐이다.
    func isEmptyNovels(_ state: PreferenceGenreNovelState) -> Bool {
        if case .novels(let novels) = state { return novels.isEmpty }
        return false
    }

    var pushAuthorizationAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isPushAuthorizationAlertPresented },
            set: { if !$0 { viewModel.handle(.dismissPushAuthorizationAlert) } }
        )
    }
}

// MARK: - Preview

#Preview {
    // VM을 직접 만든다(정본 5개 View의 Preview와 동일) — 로딩/실패 등 초기 상태를 손보기 쉽다.
    HomeView(
        viewModel: HomeViewModel(
            loadHomeDataUseCase: PreviewLoadHomeDataUseCase(),
            loadUnreadNotificationStatusUseCase: PreviewLoadUnreadNotificationStatusUseCase(),
            pushAuthorizationChecker: PreviewPushAuthorizationChecker()
        ),
        onNovelSelected: { _ in },
        onFeedSelected: { _ in },
        onSearchTapped: {},
        onDetailSearchTapped: {},
        onNotificationTapped: {},
        onPreferenceGenreSettingTapped: {},
        onAuthenticationRequired: {}
    )
}

private struct PreviewLoadHomeDataUseCase: LoadHomeDataUseCase {
    func execute() async throws(RepositoryError) -> HomeData {
        HomeData(
            nickname: "웹소소",
            todayDiscoveries: [
                TodayDiscovery(
                    novelID: NovelID(1),
                    novelTitle: "우리 집 고양이가 날 노린다",
                    novelThumbnailImage: nil,
                    novelAuthor: "캐슈",
                    novelGenre: .BL,
                    publicationStatus: .completed,
                    keywords: ["사랑꾼", "짝사랑"],
                    content: .novel,
                    contentDescription: "며칠째 아파트 주차장을 서성이는 작은 고양이가 설국화의 눈에 밟힌다."
                ),
                TodayDiscovery(
                    novelID: NovelID(2),
                    novelTitle: "괴담에 떨어져도 출근을 해야 하는구나",
                    novelThumbnailImage: nil,
                    novelAuthor: "백덕수",
                    novelGenre: .modernFantasy,
                    publicationStatus: .onGoing,
                    keywords: [],
                    // 유저 한마디 카드면 서버가 아바타를 반드시 준다(Demo mock 주석 참고).
                    content: .userComment(
                        user: Author(userId: UserID(1),
                                     nickname: "천마",
                                     profileImage: URL(string: "https://picsum.photos/seed/wssuser1/96/96"))
                    ),
                    contentDescription: "필독서 ㅇㅈ"
                )
            ],
            trendingFeeds: (1...4).map { index in
                TrendingFeed(
                    feedID: FeedID(index),
                    novelTitle: "우아한 오브리 \(index)",
                    novelThumbnailImage: nil,
                    novelGenre: .romanceFantasy,
                    description: "역대급임",
                    isSpoiler: index.isMultiple(of: 2),
                    likeCount: index * 3,
                    commentCount: index
                )
            },
            preferenceGenreNovelState: .novels((1...4).map { index in
                PreferenceGenreNovel(
                    novelID: NovelID(index),
                    novelTitle: "신데렐라는 이 멧밭쥐가 데려갑니다",
                    novelThumbnailImage: nil,
                    novelAuthors: ["이보라"],
                    interestCount: 23,
                    ratingCount: 2,
                    rating: 4.0
                )
            })
        )
    }
}

private struct PreviewLoadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase {
    func execute() async throws(RepositoryError) -> UnreadNotificationStatus {
        UnreadNotificationStatus(hasUnreadNotifications: true)
    }
}

private struct PreviewPushAuthorizationChecker: PushAuthorizationChecker {
    func authorizationStatus() async -> PushAuthorizationStatus { .authorized }
    func requestAuthorization() async -> Bool { true }
}
