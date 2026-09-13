//
//  NotificationFeatureFactory.swift
//  NotificationFeature
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import Logger
import Analytics

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 `internal`로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
///
/// 화면이 둘이라 **양쪽 다 `makeXxxView`로 이름에 대상을 넣는다**(대등한 화면 중 하나만 `makeView`로 두지 않는다).
/// 목록 → 상세 전환도 모듈이 아니라 **호출자(App)가 배선**한다 — 모듈 안에 `navigationDestination`은 없다.
public enum NotificationFeatureFactory {

    /// 알림 목록 화면. **`NavigationStack`에 push되는 화면**(홈 알림 벨에서 진입).
    ///
    /// - Parameters:
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `NotificationListRoute`(Navigation/) 참고.
    ///     실제 화면 조립·push는 호출자(App 조정 계층)가 exhaustive switch로 수행한다(#253).
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 화면 내 서버 호출 공통.
    ///     세션 이벤트라 `onRoute`에 합치지 않는다.
    @MainActor
    public static func makeNotificationListView(
        loadPagedNotificationsUseCase: LoadPagedNotificationsUseCase,
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        onRoute: @escaping (NotificationListRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = NotificationListViewModel(
            loadPagedNotificationsUseCase: loadPagedNotificationsUseCase,
            markNotificationAsReadUseCase: markNotificationAsReadUseCase,
            logger: logger,
            analyticsTracker: analyticsTracker
        )
        return NotificationListView(
            viewModel: viewModel,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 알림 상세 화면. **`NavigationStack`에 push되는 화면**(알림 목록에서 진입).
    ///
    /// - Parameters:
    ///   - notificationID: 조회 대상 알림. 진입 시점(목록 셀의 딥링크)에서 넘긴다.
    ///   - onAuthenticationRequired: 인증 만료 시 로그인 화면 진입 콜백.
    @MainActor
    public static func makeNotificationDetailView(
        notificationID: NotificationID,
        loadNotificationDetailUseCase: LoadNotificationDetailUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = NotificationDetailViewModel(
            notificationID: notificationID,
            loadNotificationDetailUseCase: loadNotificationDetailUseCase,
            logger: logger,
            analyticsTracker: analyticsTracker
        )
        return NotificationDetailView(
            viewModel: viewModel,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
