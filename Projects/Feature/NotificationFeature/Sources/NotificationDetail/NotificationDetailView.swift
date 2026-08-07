//
//  NotificationDetailView.swift
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

// 알림 상세 — 제목·작성시각·본문만 보여주는 읽기 전용 화면.
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct NotificationDetailView: View {

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: NotificationDetailViewModel

    /// 인증 만료 시 로그인 유도 콜백.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: NotificationDetailViewModel,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 실제 레이아웃은 content로 분리.
    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
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
            } else if let detail = viewModel.state.detail {
                detailSection(detail)
            }
        }
    }
}

// MARK: - Sections

private extension NotificationDetailView {

    /// 알림 본문. (레이아웃은 디자인 확인 후 구현)
    func detailSection(_ detail: NotificationDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(detail.title)
                Text(detail.createdAtText)
                Text(detail.body)
            }
        }
    }
}
