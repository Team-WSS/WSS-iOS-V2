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

    private var content: some View {
        VStack(spacing: 0) {
            headerSection
            bodySection
        }
        .background(Color.wssWhite)
    }
}

// MARK: - Sections

private extension HomeView {

    /// 로고 + 알림 벨. 스크롤과 무관하게 상단에 고정된다.
    var headerSection: some View {
        // TODO: Figma 대조 단계에서 구현
        EmptyView()
    }

    var bodySection: some View {
        // TODO: Figma 대조 단계에서 구현 — 검색바 / 상세검색 배너 /
        //       오늘의 발견 / 추천글 / 이 웹소설은 어때요?
        EmptyView()
    }
}
