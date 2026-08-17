//
//  NovelNotificationListView.swift
//  SettingFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import DesignSystem
import WSSComponent

/// 완결 알림/휴재 복귀 알림 목록 화면 — 화면 구조가 완전히 같아(#188, 사용자 확정) 제목만 바꿔 재사용한다.
struct NovelNotificationListView: View {

    @State private var viewModel: NovelNotificationListViewModel
    @Environment(\.dismiss) private var dismiss

    private let title: String
    /// 목록이 비었을 때 "작품 둘러보기" CTA — 어디로 보낼지(검색 화면 등)는 다른 Feature 모듈이라
    /// 이 화면이 알지 못한다. 호출자(App)가 결정한다.
    private let onBrowseNovels: () -> Void

    init(
        title: String,
        viewModel: NovelNotificationListViewModel,
        onBrowseNovels: @escaping () -> Void
    ) {
        self.title = title
        self._viewModel = State(initialValue: viewModel)
        self.onBrowseNovels = onBrowseNovels
    }

    var body: some View {
        content
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear {
                viewModel.handle(.load)
            }
            .showWSSAlert(
                isPresented: deleteConfirmationBinding,
                type: .deleteNovelNotificationSubscriptions(summary: deleteSummaryText),
                buttonActions: [
                    { viewModel.handle(.dismissDeleteConfirmation) },
                    { viewModel.handle(.confirmDelete) }
                ]
            )
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            LoadingView()
        } else if viewModel.state.loadError != nil {
            NetworkErrorView {
                viewModel.handle(.load)
            }
        } else if viewModel.state.subscriptions.isEmpty {
            WSSEmptyView(type: .novelNotification, action: onBrowseNovels)
        } else {
            listSection
        }
    }

    private var listSection: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(viewModel.state.subscriptions, id: \.id) { subscription in
                    NovelNotificationRow(
                        subscription: subscription,
                        isEditing: viewModel.state.isEditing,
                        isSelected: viewModel.state.selectedNovelIDs.contains(subscription.novelID),
                        onToggleSelection: { viewModel.handle(.toggleSelection(subscription.novelID)) }
                    )
                    // 무한스크롤 — 마지막 행이 화면에 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                    .onAppear {
                        if subscription.id == viewModel.state.subscriptions.last?.id {
                            viewModel.handle(.loadMore)
                        }
                    }
                }

                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Toolbar

private extension NovelNotificationListView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(title)
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }

        if !viewModel.state.subscriptions.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if viewModel.state.isEditing {
                        viewModel.handle(.presentDeleteConfirmation)
                    } else {
                        viewModel.handle(.beginEditing)
                    }
                } label: {
                    Text(viewModel.state.isEditing ? "삭제" : "수정")
                        .applyWSSFont(.title2)
                        .foregroundStyle(trailingButtonColor)
                }
                .disabled(viewModel.state.isEditing && viewModel.state.selectedNovelIDs.isEmpty)
            }
        }
    }
}

// MARK: - Presentation

private extension NovelNotificationListView {
    /// "수정"(비편집)은 gray300, "삭제"(편집 중)는 선택 여부로 gray200(비활성)/primary100(활성) — 사용자 확정 색상.
    var trailingButtonColor: Color {
        guard viewModel.state.isEditing else { return WSSColor.wssGray300.swiftUIColor }
        return viewModel.state.selectedNovelIDs.isEmpty
            ? WSSColor.wssGray200.swiftUIColor
            : WSSColor.wssPrimary100.swiftUIColor
    }

    var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedDeleteConfirmation },
            set: { if !$0 { viewModel.handle(.dismissDeleteConfirmation) } }
        )
    }

    /// "{첫 선택 작품 제목} 외 N작품" — 목록에 보이는 순서 기준으로 첫 선택 항목을 고른다.
    var deleteSummaryText: String {
        let selected = viewModel.state.subscriptions.filter { viewModel.state.selectedNovelIDs.contains($0.novelID) }
        guard let first = selected.first else { return "" }
        return selected.count == 1 ? first.novelTitle : "\(first.novelTitle) 외 \(selected.count - 1)작품"
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.toastError != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        switch viewModel.state.toastError {
        case .unknown, .none: .unknownError
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelNotificationListView(
            title: "완결 알림",
            viewModel: NovelNotificationListViewModel(
                type: .completion,
                loadSubscriptionsUseCase: PreviewLoadNovelNotificationSubscriptionsUseCase(),
                deleteSubscriptionsUseCase: PreviewDeleteNovelNotificationSubscriptionsUseCase()
            ),
            onBrowseNovels: { print("작품 둘러보기") }
        )
    }
}

private struct PreviewLoadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase {
    func execute(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        let subscriptions = (1...5).map { index in
            NovelNotificationSubscription(
                id: SubscriptionID(index),
                novelID: NovelID(index),
                novelTitle: "미리보기 작품 \(index)",
                novelThumbnailImage: nil,
                novelAuthor: "프리뷰 작가",
                registeredDateText: "2026.08.\(10 + index)"
            )
        }
        return PagedNovelNotificationSubscriptions(subscriptions: subscriptions, isLoadable: false, nextSubscriptionID: nil)
    }
}

private struct PreviewDeleteNovelNotificationSubscriptionsUseCase: DeleteNovelNotificationSubscriptionsUseCase {
    func execute(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError) {}
}
