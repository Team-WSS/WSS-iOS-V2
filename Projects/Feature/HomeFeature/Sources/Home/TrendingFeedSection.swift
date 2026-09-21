//
//  TrendingFeedSection.swift
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

/// "{닉네임}님을 위한 추천글" — 서버가 주는 6건을 **2건씩 3페이지**로 끊어 가로로 넘긴다.
/// (구 WSSiOS도 `prefix(6)` → 2개씩 묶었고, 시안의 인디케이터 3개가 그 결과다.)
struct TrendingFeedSection: View {

    let nickname: String?
    let feeds: [TrendingFeed]
    let onFeedSelected: (FeedID) -> Void

    @State private var currentPage: Int?

    private enum Metric {
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 14

        static let rowHeight: CGFloat = 122
        static let rowHorizontalPadding: CGFloat = 28
        /// 제목 줄이 **행 상단에서 늘 이 자리**여야 한다(본문 줄 수와 무관하게).
        static let textTopPadding: CGFloat = 23
        /// 썸네일은 위아래 16으로 행을 꽉 채운다(16 + 90 + 16 = 122).
        static let thumbnailTopPadding: CGFloat = 16
        static let textSpacing: CGFloat = 4
        /// 제목·본문과 표지 사이 간격. 텍스트가 **남는 폭을 전부** 먹으므로 이 값이 곧 둘 사이 여백이다.
        static let rowSpacing: CGFloat = 20

        static let thumbnailWidth: CGFloat = 64
        static let thumbnailHeight: CGFloat = 90
        static let thumbnailCornerRadius: CGFloat = 8
        static let genreMarkSize: CGFloat = 30

        static let cornerRadius: CGFloat = 14
        static let feedsPerPage = 2

        static let indicatorActiveWidth: CGFloat = 16
        static let indicatorSize: CGFloat = 6
        static let indicatorSpacing: CGFloat = 6
    }

    /// 6건 → [[2건], [2건], [2건]]. 마지막 페이지는 1건일 수 있다.
    private var pages: [[TrendingFeed]] {
        stride(from: 0, to: feeds.count, by: Metric.feedsPerPage).map { start in
            Array(feeds[start..<min(start + Metric.feedsPerPage, feeds.count)])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionTitle
            Spacer().frame(height: Metric.sectionSpacing)
            pagedCards
            Spacer().frame(height: Metric.sectionSpacing)
            pageIndicator
        }
    }
}

// MARK: - Sections

private extension TrendingFeedSection {

    var sectionTitle: some View {
        HStack(spacing: 0) {
            // 닉네임은 로컬 캐시라 없을 수 있다 — 그땐 주어 없이 "추천글"만 남긴다.
            Text(nickname.map { "\($0)님을 위한 추천글" } ?? "추천글")
                .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }

    var pagedCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // ⚠️ 페이지 간 간격이 0이면 카드와 좌우 여백의 합이 화면 폭과 같아져
            // **다음 페이지가 여백만큼 삐져나와** 보인다. 간격을 줘야 한 장만 보인다.
            // 마지막 페이지가 1건(홀수)이면 기본 `.center` 정렬에서 반쪽 카드가 세로 가운데로 뜬다.
            LazyHStack(alignment: .top, spacing: Metric.horizontalPadding) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageCard(page)
                        // ⚠️ 시안 폭(375 기준 335)을 **상수로 박지 말 것** — 393·430pt 기기에서
                        // 그만큼 다음 페이지가 옆에 딸려 보인다("한 장만 보인다" 계약 위반).
                        // `contentMargins`를 뺀 실제 콘텐츠 폭을 받아 기기 폭을 따라가게 한다.
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentPage)
        // 카드가 화면보다 좁아 페이지 단위 스냅(.paging) 대신 뷰 정렬 스냅을 쓴다.
        .contentMargins(.horizontal, Metric.horizontalPadding, for: .scrollContent)
    }

    /// 한 페이지 = 위아래로 붙은 행 2개가 테두리 하나를 공유하는 카드.
    func pageCard(_ page: [TrendingFeed]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(page.enumerated()), id: \.element.feedID) { index, feed in
                if index > 0 {
                    Rectangle()
                        .fill(Color.wssGray80)
                        .frame(height: 1)
                }
                feedRow(feed)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Metric.cornerRadius)
                .strokeBorder(Color.wssGray80, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
    }

    func feedRow(_ feed: TrendingFeed) -> some View {
        Button {
            onFeedSelected(feed.feedID)
        } label: {
            // ⚠️ **세로 가운데 정렬로 두지 말 것** — 본문 줄 수가 1줄(스포일러 안내)~3줄로 갈려서,
            // 가운데 정렬이면 행마다·페이지마다 제목 줄의 높이가 들쭉날쭉해진다.
            // 제목은 행 상단에서 23, 본문은 제목에서 4 — **위에서부터 고정**으로 쌓는다.
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(feed.novelTitle)
                        .applyWSSFont(.title3, color: .wssBlack, alignment: .leading)
                        .lineLimit(1)

                    Spacer().frame(height: Metric.textSpacing)

                    // 스포일러 글은 본문 대신 안내 문구를 빨간색으로 대체한다(카피·색 결정은 View 몫).
                    Text(feed.isSpoiler ? "스포일러가 포함된 글 보기" : feed.description)
                        .applyWSSFont(.body5,
                                      color: feed.isSpoiler ? .wssSecondary100 : .wssBlack,
                                      alignment: .leading)
                        .lineLimit(feed.isSpoiler ? 1 : 3)
                }
                // ⚠️ 시안 폭(375 기준 195 = 335 - 28*2 - 64 - 20)을 **상수로 박지 말 것** —
                // 393·430pt 기기에서 남는 폭이 그대로 텍스트 오른쪽에 빈 자리로 남아
                // 표지와의 간격이 20보다 벌어진다. 남는 폭을 텍스트가 전부 먹게 두면
                // 표지와의 간격은 아래 고정 간격(20)으로 기기 폭과 무관하게 유지된다.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Metric.textTopPadding)

                Spacer().frame(width: Metric.rowSpacing)

                WSSNovelCoverImage(url: feed.novelThumbnailImage)
                    .frame(width: Metric.thumbnailWidth, height: Metric.thumbnailHeight)
                    .overlay(alignment: .bottomTrailing) {
                        feed.novelGenre.markImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metric.genreMarkSize, height: Metric.genreMarkSize)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Metric.thumbnailCornerRadius))
                    .padding(.top, Metric.thumbnailTopPadding)
            }
            .padding(.horizontal, Metric.rowHorizontalPadding)
            .frame(height: Metric.rowHeight, alignment: .top)
            .contentShape(Rectangle())
        }
    }

    var pageIndicator: some View {
        HStack(spacing: Metric.indicatorSpacing) {
            ForEach(pages.indices, id: \.self) { index in
                let isCurrent = (currentPage ?? 0) == index

                Capsule()
                    .fill(isCurrent ? Color.wssBlack : Color.wssGray100)
                    .frame(width: isCurrent ? Metric.indicatorActiveWidth : Metric.indicatorSize,
                           height: Metric.indicatorSize)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: currentPage)
    }
}
