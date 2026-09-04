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

    private enum Metric {
        static let cellPadding: CGFloat = 20
        static let iconSize: CGFloat = 36
        static let iconCornerRadius: CGFloat = 12
        /// 배경 캡슐(36) 안에 놓이는 서버 아이콘 이미지 크기 — 시안의 인셋 4.5.
        static let iconImageSize: CGFloat = 27
        /// 아이콘 ↔ 텍스트 사이.
        static let iconTextSpacing: CGFloat = 14
        /// 제목 ↔ 본문 사이.
        static let titleBodySpacing: CGFloat = 2
        /// 본문 ↔ 작성시각 사이.
        static let bodyDateSpacing: CGFloat = 14
        static let separatorHeight: CGFloat = 1
    }

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: NotificationListViewModel
    @Environment(\.dismiss) private var dismiss

    /// 알림 상세 딥링크 → 상세 화면 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    private let onNotificationSelected: (NotificationID) -> Void
    /// 피드 딥링크 → 피드 상세 진입 콜백.
    private let onFeedSelected: (FeedID) -> Void
    /// 작품 딥링크 → 작품 상세 진입 콜백. 완결·휴재 복귀 알림이 응답의 `novelId`로 여기에 실린다.
    private let onNovelSelected: (NovelID) -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 화면 내 모든 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: NotificationListViewModel,
        onNotificationSelected: @escaping (NotificationID) -> Void,
        onFeedSelected: @escaping (FeedID) -> Void,
        onNovelSelected: @escaping (NovelID) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNotificationSelected = onNotificationSelected
        self.onFeedSelected = onFeedSelected
        self.onNovelSelected = onNovelSelected
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 디자인 폰트·뒤로가기 아이콘을 맞추려고 시스템 네비바를 숨기고 커스텀 헤더를 쓴다.
    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            // 네비바를 숨기면 스와이프 뒤로가기까지 함께 꺼진다 → 제스처만 따로 되살린다.
            .enableSwipeBack()
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "알림") { dismiss() }
            // 로딩·실패는 네비게이션 바만 남기고 그 아래를 통째로 대체한다(Library와 같은 규칙).
            if viewModel.state.isLoading {
                LoadingView()
            } else if let error = viewModel.state.loadFailed {
                NetworkErrorView(error: error) { viewModel.handle(.retry) }
            } else if viewModel.state.items.isEmpty {
                // CTA 없는 빈 상태 — 알림은 유도할 행동이 마땅치 않다(#181에서 확정).
                WSSEmptyView(type: .notification)
            } else {
                listSection
            }
        }
        .background(Color.wssWhite)
    }
}

// MARK: - Sections

private extension NotificationListView {

    /// 알림 목록 — 마지막 셀이 보이면 다음 페이지를 요청한다.
    var listSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.state.items.enumerated()), id: \.element.id) { index, item in
                    // 구분선은 셀 사이에만 둔다(첫 셀 위엔 없음 — 네비게이션 바와 붙어버린다).
                    if index > 0 {
                        separator
                    }
                    notificationCell(item)
                        .onAppear { loadMoreIfLast(item) }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
        }
    }

    var separator: some View {
        Rectangle()
            .fill(Color.wssGray50)
            .frame(height: Metric.separatorHeight)
    }

    /// 알림 한 건 — 아이콘 + (제목 / 본문 / 작성시각).
    /// 미읽음은 셀 배경을 `wssPrimary20`으로 칠해 구분한다(읽으면 흰색).
    func notificationCell(_ item: NotificationItem) -> some View {
        Button {
            select(item)
        } label: {
            HStack(alignment: .top, spacing: 0) {
                notificationIcon(item)

                Spacer().frame(width: Metric.iconTextSpacing)

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        // ⚠️ alignment를 인자로 넘겨야 한다 — 기본값이 .center라 밖에서 .multilineTextAlignment를
                        // 걸어도 Text에 더 가까운 안쪽 값이 이겨 무시된다.
                        .applyWSSFont(.title2, color: .wssBlack, alignment: .leading)
                        .lineLimit(1)

                    Spacer().frame(height: Metric.titleBodySpacing)

                    Text(item.body)
                        .applyWSSFont(.body5, color: .wssGray200, alignment: .leading)
                        .lineLimit(2)

                    Spacer().frame(height: Metric.bodyDateSpacing)

                    Text(item.createdAtText)
                        .applyWSSFont(.body5, color: .wssGray200, alignment: .leading)
                }
                // 시안의 텍스트 프레임 폭(270)은 샘플 문구 기준이라 옮기지 않는다 — 남는 폭을 전부 쓰게 두면
                // 기기 폭이 달라져도 아이콘과의 간격(14)이 그대로 유지된다(HomeFeature 교훈).
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Metric.cellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(item.isRead ? Color.wssWhite : Color.wssPrimary20)
            .contentShape(Rectangle())
        }
        // 읽음 처리로 배경색이 바뀌므로 짧은 명시 애니메이션을 건다(미설정 시 기본 크로스페이드가 느리게 번진다).
        .animation(.easeInOut(duration: 0.1), value: item.isRead)
    }

    /// 알림 아이콘 — 배경 캡슐만 로컬로 그리고 그 위에 **서버가 준 이미지**를 얹는다.
    /// 알림 종류별 아이콘은 DesignSystem에 없다(`NotificationItem.iconURL`이 유일한 출처).
    func notificationIcon(_ item: NotificationItem) -> some View {
        WSSAsyncImage(url: item.iconURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: { _ in
            // 이미지가 없으면 배경 캡슐만 남는다 — 자리를 지켜야 텍스트가 밀리지 않는다.
            // 로딩 중에도 같은 화면에 여러 알림 아이콘이 동시에 뜨므로 스피너 없이 조용히 비워둔다.
            Color.clear
        }
        // 아이콘 이미지는 배경보다 작다(시안: 배경 36 안에 27) — 배경 캡슐이 이미지에 가려지지 않게 한다.
        .frame(width: Metric.iconImageSize, height: Metric.iconImageSize)
        .frame(width: Metric.iconSize, height: Metric.iconSize)
        .background(Color.wssPrimary20)
        .clipShape(RoundedRectangle(cornerRadius: Metric.iconCornerRadius))
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
        // 상수로 두지 않고 switch로 받는다 — 토스트 케이스가 늘면 컴파일러가 여기를 짚어준다.
        switch viewModel.state.presentedToast {
        // 더보기 실패는 네트워크 실패 계열 — 정본(Library·NovelDetail)과 동일하게 unknownError로 표현.
        case .loadMoreFailed, .none: .unknownError
        }
    }

    /// 셀 탭 — 읽음 처리는 VM에, 화면 전환은 딥링크에 따라 상위 콜백에 위임한다.
    /// `.unknown`(작품 알림 등 갈 곳이 없는 경우)도 **읽음 처리는 한다** — 전환만 없다(#181에서 확정).
    /// ⚠️ 읽음 표시는 전 케이스 즉시 반영되지만 **read API 호출 여부는 딥링크마다 다르다**
    /// (상세로 가는 알림은 서버가 상세 조회로 읽음 처리한다) — 그 분기는 VM이 소유하니 여기서 흉내내지 말 것.
    func select(_ item: NotificationItem) {
        viewModel.handle(.selectNotification(item))
        switch item.deeplink {
        case .notificationDetail(let id):
            onNotificationSelected(id)
        case .feedDetail(let id):
            onFeedSelected(id)
        case .novelDetail(let id):
            onNovelSelected(id)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationListView(
            viewModel: NotificationListViewModel(
                loadPagedNotificationsUseCase: PreviewLoadPagedNotificationsUseCase(),
                markNotificationAsReadUseCase: PreviewMarkNotificationAsReadUseCase()
            ),
            onNotificationSelected: { print("알림 상세: \($0)") },
            onFeedSelected: { print("피드 상세: \($0)") },
            onNovelSelected: { print("작품 상세: \($0)") },
            onAuthenticationRequired: { print("로그인 유도") }
        )
    }
}

private struct PreviewLoadPagedNotificationsUseCase: LoadPagedNotificationsUseCase {
    func execute(lastNotificationID: NotificationID?, size: Int) async throws(RepositoryError) -> PagedNotifications {
        // 읽음·미읽음과 딥링크 3종을 섞어 셀 배경 구분과 말줄임을 함께 본다.
        let items = [
            NotificationItem(
                id: NotificationID(1),
                iconURL: nil,
                title: "웹소소 이용약관 개정 안내",
                body: "서비스 이용약관이 개정되어 안내드립니다. 개정된 약관은 2026년 8월 20일부터 적용됩니다.",
                createdAtText: "방금 전",
                isRead: false,
                deeplink: .notificationDetail(id: NotificationID(1))
            ),
            NotificationItem(
                id: NotificationID(2),
                iconURL: nil,
                title: "‘여주가 세계를 구함 이 구역의 최강자다’ 라는 아주 긴 제목",
                body: "내가 댓글 단 수다글에 또 다른 댓글이 달렸어요.",
                createdAtText: "3시간 전",
                isRead: false,
                deeplink: .feedDetail(id: FeedID(7))
            ),
            NotificationItem(
                id: NotificationID(3),
                iconURL: nil,
                title: "완결 알림",
                body: "<당신의 이해를 돕기 위하여> 작품이 완결났어요.",
                createdAtText: "2026.07.31",
                isRead: true,
                deeplink: .unknown
            )
        ]
        return PagedNotifications(items: items, isLoadable: false)
    }
}

private struct PreviewMarkNotificationAsReadUseCase: MarkNotificationAsReadUseCase {
    func execute(id: NotificationID) async throws(RepositoryError) {}
}
