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
import DesignSystem
import WSSComponent

/// 홈 탭 콘텐츠. 추천 3종을 한 화면에 모아 보여주고, 선택 결과는 전부 상위로 위임한다.
/// "얇은 VM": 카피·포맷·색은 전부 이 View가 결정한다.
struct HomeView: View {

    @State private var viewModel: HomeViewModel
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
            .onAppear { viewModel.handle(.load) }
            .onChange(of: viewModel.state.requiresAuthentication) { _, requiresAuthentication in
                guard requiresAuthentication else { return }
                // 홈은 탭 콘텐츠라 VM이 앱 세션 내내 산다 → 신호를 소진해야 2회차 만료가 삼켜지지 않는다.
                viewModel.handle(.consumeAuthenticationRequired)
                onAuthenticationRequired()
            }
    }

    /// 헤더만 고정이고 그 아래가 통째로 스크롤/로딩/실패로 갈린다(구 WSSiOS와 같은 경계).
    private var content: some View {
        VStack(spacing: 0) {
            HomeHeaderView(
                hasUnreadNotifications: viewModel.state.hasUnreadNotifications,
                onNotificationTapped: onNotificationTapped
            )

            body(for: viewModel.state)
        }
        .background(Color.wssWhite)
    }

    @ViewBuilder
    private func body(for state: HomeViewModel.State) -> some View {
        if state.loadFailed {
            NetworkErrorView { viewModel.handle(.load) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if state.isLoading {
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
        ScrollView {
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
}
