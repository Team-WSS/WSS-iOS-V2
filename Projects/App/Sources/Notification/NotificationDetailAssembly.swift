//
//  NotificationDetailAssembly.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import NotificationFeature

/// 알림 상세(`NotificationFeatureFactory.makeNotificationDetailView`) 조립 공용 헬퍼.
/// 원래 홈 알림 목록에서 상세로 갈 때만 필요해 `HomeRootView`가 인라인으로 갖고 있었으나, #243에서 공지 푸시
/// 딥링크(`view=notificationDetail`)가 **어느 탭에서든** 열려야 해서(딥링크는 선택된 탭 위에 push) 4탭이 공유하도록
/// 뽑았다 — 앱 내 목록→상세 전환과 푸시 딥링크가 같은 화면·같은 UseCase를 쓴다.
/// `onAuthenticationRequired`만 호출자별로 다르다(각 탭 Root가 자기 인증만료 콜백을 넘긴다).
@MainActor
enum NotificationDetailAssembly {
    static func makeView(
        notificationID: NotificationID,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NotificationFeatureFactory.makeNotificationDetailView(
            notificationID: notificationID,
            loadNotificationDetailUseCase: DefaultLoadNotificationDetailUseCase(repository: dependencies.notificationRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
