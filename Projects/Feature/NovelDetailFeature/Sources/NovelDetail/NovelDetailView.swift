//
//  NovelDetailView.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import FeedDomain
import DesignSystem
import WSSComponent

// 작품 상세 화면: 헤더(작품 정보·관심 토글) + 탭(정보/피드).
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
// ⚠️ 현재는 골격 — 실제 레이아웃·디자인은 ③(Figma) 단계에서 대체된다.
struct NovelDetailView: View {

    @State private var viewModel: NovelDetailViewModel
    /// 작품 평가(NovelReviewFeature) 진입 콜백. Feature 간 직접 의존 금지 —
    /// 화면 전환은 호출자(App 조정 계층)가 수행하고, 이 화면은 로드된 정보만 넘긴다.
    private let onReviewTapped: (NovelInformation) -> Void

    init(
        viewModel: NovelDetailViewModel,
        onReviewTapped: @escaping (NovelInformation) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onReviewTapped = onReviewTapped
    }

    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
    }

    private var content: some View {
        Group {
            if let information = viewModel.state.information {
                loadedContent(information)
            } else if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 로드 실패 빈 상태 골격(문구·재시도 UI는 ③에서 디자인 확정).
                Text("작품 정보를 불러오지 못했어요")
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssGray200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadedContent(_ information: NovelInformation) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(information)
                Spacer().frame(height: 24)
                tabSection
                Spacer().frame(height: 24)
                switch viewModel.state.selectedTab {
                case .info:
                    infoSection(information)
                case .feed:
                    feedSection
                }
            }
        }
    }
}

// MARK: - Sections

private extension NovelDetailView {

    /// 헤더 골격: 제목·작가·관심 토글·평가 진입.
    func headerSection(_ information: NovelInformation) -> some View {
        VStack(spacing: 0) {
            Text(information.novel.title)
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
            Spacer().frame(height: 8)
            Text(information.novel.authors.joined(separator: ", "))
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssGray200)
            Spacer().frame(height: 16)
            interestButton
            Spacer().frame(height: 8)
            reviewButton(information)
        }
    }

    /// 관심 토글 골격. 상태·카운트는 VM(state.novel)이, 라벨 표현은 View가 결정.
    var interestButton: some View {
        Button {
            viewModel.handle(.toggleInterest)
        } label: {
            Text(interestLabel)
                .applyWSSFont(.body4)
                .foregroundStyle(isInterested ? Color.wssPrimary100 : Color.wssGray200)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    /// 작품 평가 진입 골격(CTA 디자인은 ③에서 확정 — WSSCTAButton 채택 여부 포함).
    func reviewButton(_ information: NovelInformation) -> some View {
        Button {
            onReviewTapped(information)
        } label: {
            Text("작품 평가하기")
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssPrimary100)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    /// 정보/피드 커스텀 탭 골격.
    var tabSection: some View {
        HStack(spacing: 0) {
            ForEach(NovelDetailViewModel.Tab.allCases, id: \.self) { tab in
                Button {
                    viewModel.handle(.selectTab(tab))
                } label: {
                    Text(tabTitle(tab))
                        .applyWSSFont(.title3)
                        .foregroundStyle(
                            viewModel.state.selectedTab == tab ? Color.wssBlack : Color.wssGray200
                        )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
    }

    /// 정보 탭 골격: 작품 소개만 우선 표시(플랫폼·키워드·통계는 ③에서).
    func infoSection(_ information: NovelInformation) -> some View {
        Text(information.description)
            .applyWSSFont(.body4)
            .foregroundStyle(Color.wssBlack)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }

    /// 피드 탭 골격: 내용 텍스트 목록 + 커서 페이지네이션 트리거.
    var feedSection: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.state.feeds, id: \.feedId) { feed in
                Text(feed.content)
                    .applyWSSFont(.body4)
                    .foregroundStyle(Color.wssBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .onAppear {
                        // 마지막 행 노출 시 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                        if feed == viewModel.state.feeds.last {
                            viewModel.handle(.loadMoreFeeds)
                        }
                    }
                Spacer().frame(height: 16)
            }
            if viewModel.state.isLoadingFeeds {
                ProgressView()
            }
        }
    }
}

// MARK: - Presentation

private extension NovelDetailView {

    var isInterested: Bool {
        viewModel.state.novel?.isInterested == true
    }

    var interestLabel: String {
        let count = viewModel.state.novel?.interestCount ?? 0
        return isInterested ? "관심 해제 (\(count))" : "관심 등록 (\(count))"
    }

    func tabTitle(_ tab: NovelDetailViewModel.Tab) -> String {
        switch tab {
        case .info: "정보"
        case .feed: "피드"
        }
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// 에러 의미값 → 토스트 표현 매핑(골격 — 케이스별 문구는 ③에서 디자인 확정 후 정제).
    var toastType: WSSToastType {
        .unknownError
    }
}
