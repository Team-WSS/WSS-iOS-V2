//
//  LibraryListCell.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 리스트 모드 셀 — 뱃지+날짜 / 썸네일+정보(제목·별점·매력포인트) / 키워드 칩 행.
// 디자인 정본은 "한줄평 뺌" 버전(31733:94684) — 한줄평 없음.
struct LibraryListCell: View {

    let novel: LibraryNovel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasBadgeRow {
                badgeRow
                Spacer().frame(height: 8)
            }
            infoRow
            if let keywords = novel.userReview?.keywords, !keywords.isEmpty {
                Spacer().frame(height: 8)
                keywordRow(keywords)
            }
        }
    }

    private var hasBadgeRow: Bool {
        novel.userReview?.readingStatus != nil
    }

    // MARK: - Rows

    /// 상태 뱃지(고정폭 60) + 날짜.
    private var badgeRow: some View {
        HStack(spacing: 0) {
            if let status = novel.userReview?.readingStatus {
                Text(status.statusName)
                    .applyWSSFont(.label2, color: .wssWhite)
                    .padding(.vertical, 4)
                    .frame(width: 60)
                    .background(status.tagBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            if let dateText = LibraryDateFormatter.text(for: novel.userReview?.period) {
                Spacer().frame(width: 16)
                Text(dateText)
                    .applyWSSFont(.body5, color: .wssGray300)
            }
        }
    }

    private var infoRow: some View {
        HStack(alignment: .top, spacing: 0) {
            thumbnail
            Spacer().frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(novel.title)
                    .applyWSSFont(.title2, color: .wssBlack, alignment: .leading)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer().frame(height: 6)
                ratingRow
                if let points = novel.userReview?.attractivePoint, !points.isEmpty {
                    Spacer().frame(height: 6)
                    attractivePointRow(points)
                }
            }
        }
    }

    /// 이미지가 없거나 로딩/실패면 WSS 빈 표지(`imgLoadingThumbnail`)로 대체한다(정본: NovelDetail 헤더).
    private var thumbnail: some View {
        AsyncImage(url: novel.thumbnailImage) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                WSSImage.imgLoadingThumbnail.swiftUIImage
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 60, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomTrailing) {
            if novel.isInterested {
                WSSImage.icHeartFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
        }
    }

    /// 내 별점(빨강·Medium) + 전체 별점(회색·Regular). 내 별점 없으면 전체 별점만.
    private var ratingRow: some View {
        HStack(spacing: 10) {
            if let rating = novel.userReview?.rating {
                HStack(spacing: 5) {
                    HStack(spacing: 2) {
                        WSSImage.icSmallStarFilled.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text(ratingText(Float(rating.value)))
                            .applyWSSFont(.body5_2, color: .wssSecondary100)
                    }
                    Text("내 별점")
                        .applyWSSFont(.body5, color: .wssGray300)
                }
            }
            HStack(spacing: 5) {
                HStack(spacing: 2) {
                    WSSImage.icSmallStarEmpty.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    Text(ratingText(novel.rating))
                        .applyWSSFont(.body5, color: .wssGray200)
                }
                Text("전체 별점")
                    .applyWSSFont(.body5, color: .wssGray200)
            }
        }
    }

    /// 매력포인트 — 아이콘 12px + 이름, 항목 사이 2px 점 구분자.
    private func attractivePointRow(_ points: [AttractivePoint]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                if index > 0 {
                    Circle()
                        .fill(Color.wssGray100)
                        .frame(width: 2, height: 2)
                }
                HStack(spacing: 3) {
                    point.iconImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    Text(point.displayName)
                        .applyWSSFont(.body5, color: .wssGray300)
                }
            }
        }
    }

    /// 키워드 칩 — 한 줄, 넘치면 잘림(디자인 overflow-clip).
    private func keywordRow(_ keywords: [Keyword]) -> some View {
        HStack(spacing: 6) {
            ForEach(keywords) { keyword in
                Text(keyword.name)
                    .applyWSSFont(.body5, color: .wssGray200)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.wssPrimary20)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    private func ratingText(_ value: Float) -> String {
        String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 28) {
        LibraryListCell(
            novel: LibraryNovel(
                id: NovelID(1),
                title: "당신의 이해를 돕기 위하여",
                thumbnailImage: nil,
                rating: 4.2,
                isInterested: true,
                userReview: UserNovelReview(
                    readingStatus: .watching,
                    rating: try? Rating(4.0),
                    attractivePoint: [.character, .vibe],
                    period: nil,
                    keywords: [Keyword(id: KeywordID(1), name: "빙의")]
                ),
                writtenFeeds: []
            )
        )
        // 평가 없는 작품 — 뱃지·별점·매력포인트·키워드 행이 숨는다.
        LibraryListCell(
            novel: LibraryNovel(
                id: NovelID(2),
                title: "전지적 독자 시점",
                thumbnailImage: nil,
                rating: 4.2,
                isInterested: true,
                userReview: nil,
                writtenFeeds: []
            )
        )
    }
    .padding(.horizontal, 20)
}
