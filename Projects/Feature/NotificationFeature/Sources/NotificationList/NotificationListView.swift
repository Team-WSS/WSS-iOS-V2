//
//  NotificationListView.swift
//  NotificationFeature
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import DesignSystem
import WSSComponent

// 알림 목록 — 커서 페이지네이션으로 알림을 조회하고, 셀 탭 시 읽음 처리 + 딥링크 전환을 상위에 위임한다.
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct NotificationListView: View {

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: NotificationListViewModel

    /// 알림 상세 딥링크 → 상세 화면 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    private let onNotificationSelected: (NotificationID) -> Void
    /// 피드 딥링크 → 피드 상세 진입 콜백.
    private let onFeedSelected: (FeedID) -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 화면 내 모든 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: NotificationListViewModel,
        onNotificationSelected: @escaping (NotificationID) -> Void,
        onFeedSelected: @escaping (FeedID) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNotificationSelected = onNotificationSelected
        self.onFeedSelected = onFeedSelected
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 실제 레이아웃은 content로 분리.
    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
            }
    }

    private var content: some View {
        Group {
            if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
            } else if viewModel.state.items.isEmpty {
                emptySection
            } else {
                listSection
            }
        }
    }
}

// MARK: - Sections

private extension NotificationListView {

    /// 알림이 하나도 없을 때. (문구·CTA는 디자인 확인 후 확정)
    var emptySection: some View {
        Color.wssWhite
    }

    /// 알림 목록 — 마지막 셀이 보이면 다음 페이지를 요청한다.
    var listSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.state.items, id: \.id) { item in
                    notificationCell(item)
                        .onAppear { loadMoreIfLast(item) }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                }
            }
        }
    }

    /// 알림 한 건. (셀 레이아웃은 디자인 확인 후 구현)
    func notificationCell(_ item: NotificationItem) -> some View {
        Button {
            select(item)
        } label: {
            Text(item.title)
        }
    }
}

// MARK: - Presentation

private extension NotificationListView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        // 더보기 실패는 네트워크 실패 계열 — 정본(Library·NovelDetail)과 동일하게 unknownError로 표현.
        .unknownError
    }

    /// 셀 탭 — 읽음 처리는 VM에, 화면 전환은 딥링크에 따라 상위 콜백에 위임한다.
    func select(_ item: NotificationItem) {
        viewModel.handle(.selectNotification(item))
        switch item.deeplink {
        case .notificationDetail(let id):
            onNotificationSelected(id)
        case .feedDetail(let id):
            onFeedSelected(id)
        case .unknown, .none:
            break
        }
    }

    func loadMoreIfLast(_ item: NotificationItem) {
        if item.id == viewModel.state.items.last?.id {
            viewModel.handle(.loadMore)
        }
    }
}
