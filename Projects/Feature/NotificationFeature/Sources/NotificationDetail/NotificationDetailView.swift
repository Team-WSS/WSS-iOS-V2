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

// 알림 상세 — 제목·작성시각·본문만 보여주는 읽기 전용 화면(공지·이벤트 알림이 여기로 들어온다).
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct NotificationDetailView: View {

    private enum Metric {
        /// 커스텀 네비게이션 바 높이 — 시스템 네비바(inline)와 같은 44.
        static let navigationBarHeight: CGFloat = 44
        static let backButtonSize: CGFloat = 44
        static let backIconSize: CGFloat = 24
        static let backButtonLeading: CGFloat = 6
        static let horizontalPadding: CGFloat = 20
        static let headerVerticalPadding: CGFloat = 20
        /// 제목 ↔ 작성시각 사이.
        static let titleDateSpacing: CGFloat = 10
        /// 구분선 ↔ 본문 사이.
        static let separatorBodySpacing: CGFloat = 24
        static let separatorHeight: CGFloat = 1
        /// 본문 아래 여유 — 짧은 본문이 화면 바닥에 붙지 않게 시안이 잡아둔 값.
        static let bottomSpacing: CGFloat = 200
    }

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: NotificationDetailViewModel
    @Environment(\.dismiss) private var dismiss

    /// 인증 만료 시 로그인 유도 콜백.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: NotificationDetailViewModel,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 목록과 같은 커스텀 네비바를 쓴다.
    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            // 네비바를 숨기면 스와이프 뒤로가기까지 함께 꺼진다 → 제스처만 따로 되살린다.
            .enableSwipeBack()
            .onAppear { viewModel.handle(.load) }
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            navigationBar
            // 로딩·실패는 네비게이션 바만 남기고 그 아래를 통째로 대체한다(목록과 같은 규칙).
            if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
            } else if let detail = viewModel.state.detail {
                detailSection(detail)
            } else {
                Spacer()
            }
        }
        .background(Color.wssWhite)
    }
}

// MARK: - Sections

private extension NotificationDetailView {

    /// 커스텀 네비게이션 바 — 뒤로가기 + 중앙 "알림" 타이틀(목록과 동일).
    /// 타이틀을 `ZStack` 중앙에 두는 건 의도다 — `HStack`에 넣으면 뒤로가기 버튼 폭만큼 오른쪽으로 밀린다.
    var navigationBar: some View {
        ZStack {
            Text("알림")
                .applyWSSFont(.title2, color: .wssBlack)
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    WSSImage.icNavigateLeft.swiftUIImage
                        // ⚠️ 이 에셋의 원색은 연회색(#C7C7D0)이라 template으로 검정을 입혀야 시안과 맞는다.
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssBlack)
                        .frame(width: Metric.backIconSize, height: Metric.backIconSize)
                        // 아이콘 24를 44 히트 영역 가운데 둔다(디자인의 44 탭 타겟).
                        .frame(width: Metric.backButtonSize, height: Metric.backButtonSize)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.leading, Metric.backButtonLeading)
        }
        .frame(height: Metric.navigationBarHeight)
    }

    /// 제목·작성시각 헤더 → 구분선 → 본문.
    /// 구분선만 화면 폭을 꽉 채우고(좌우 여백 없음) 나머지는 20씩 들여쓴다 — 시안 그대로.
    func detailSection(_ detail: NotificationDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(detail.title)
                    // ⚠️ alignment를 인자로 넘겨야 한다 — 기본값이 .center라 밖에서 .multilineTextAlignment를
                    // 걸어도 Text에 더 가까운 안쪽 값이 이겨 무시된다.
                    .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)

                Spacer().frame(height: Metric.titleDateSpacing)

                Text(detail.createdAtText)
                    .applyWSSFont(.body5, color: .wssGray200, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metric.horizontalPadding)
            .padding(.vertical, Metric.headerVerticalPadding)

            Rectangle()
                .fill(Color.wssGray50)
                .frame(height: Metric.separatorHeight)

            Spacer().frame(height: Metric.separatorBodySpacing)

            Text(detail.body)
                .applyWSSFont(.body2, color: .wssBlack, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Metric.horizontalPadding)

            Spacer().frame(height: Metric.bottomSpacing)
        }
    }
}
