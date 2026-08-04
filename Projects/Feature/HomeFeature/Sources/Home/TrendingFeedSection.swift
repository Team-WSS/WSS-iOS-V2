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
        static let cardWidth: CGFloat = 335
        static let sectionSpacing: CGFloat = 14

        static let rowHeight: CGFloat = 122
        static let rowHorizontalPadding: CGFloat = 28
        static let rowVerticalPadding: CGFloat = 16
        static let textWidth: CGFloat = 195
        static let textSpacing: CGFloat = 4
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
            // ⚠️ 페이지 간 간격이 0이면 카드 폭(335)+좌우 여백(20)이 화면 폭과 같아져
            // **다음 페이지가 20pt 삐져나와** 보인다. 여백만큼 띄워야 한 장만 보인다.
            LazyHStack(spacing: Metric.horizontalPadding) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageCard(page)
                        .frame(width: Metric.cardWidth)
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
            HStack(spacing: Metric.rowSpacing) {
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
                .frame(width: Metric.textWidth, alignment: .leading)

                WSSNovelCoverImage(url: feed.novelThumbnailImage)
                    .frame(width: Metric.thumbnailWidth, height: Metric.thumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.thumbnailCornerRadius))
                    .overlay(alignment: .bottomTrailing) {
                        feed.novelGenre.markImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: Metric.genreMarkSize, height: Metric.genreMarkSize)
                    }
            }
            .padding(.horizontal, Metric.rowHorizontalPadding)
            .padding(.vertical, Metric.rowVerticalPadding)
            .frame(height: Metric.rowHeight)
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
