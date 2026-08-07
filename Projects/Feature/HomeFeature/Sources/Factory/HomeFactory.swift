//
//  HomeFactory.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import RecommendationDomain
import NotificationDomain
import Logger

/// 홈 화면의 유일한 public 진입점. View/ViewModel은 internal로 감춘다.
public enum HomeFactory {

    /// 탭 **콘텐츠만** 반환한다 — 탭바·화면 전환은 App 몫이라 선택 결과를 전부 콜백으로 올린다.
    /// - Parameter onAuthenticationRequired: 인증 만료 신호. 화면(또는 루트) 교체는 호출자가 하며,
    ///   한 번의 로드에서 여러 번 발화할 수 있으므로 **idempotent해야 한다**.
    @MainActor
    public static func makeView(
        loadHomeDataUseCase: LoadHomeDataUseCase,
        loadUnreadNotificationStatusUseCase: LoadUnreadNotificationStatusUseCase,
        logger: Logger? = nil,
        onNovelSelected: @escaping (NovelID) -> Void,
        onFeedSelected: @escaping (FeedID) -> Void,
        onSearchTapped: @escaping () -> Void,
        onDetailSearchTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void,
        onPreferenceGenreSettingTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        HomeView(
            viewModel: HomeViewModel(
                loadHomeDataUseCase: loadHomeDataUseCase,
                loadUnreadNotificationStatusUseCase: loadUnreadNotificationStatusUseCase,
                logger: logger
            ),
            onNovelSelected: onNovelSelected,
            onFeedSelected: onFeedSelected,
            onSearchTapped: onSearchTapped,
            onDetailSearchTapped: onDetailSearchTapped,
            onNotificationTapped: onNotificationTapped,
            onPreferenceGenreSettingTapped: onPreferenceGenreSettingTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
