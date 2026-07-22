//
//  LibraryGridCell.swift
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

// 그리드 모드 셀 — 표지(상태 뱃지·관심 하트 오버레이) + 제목 + 내 별점 + 날짜.
struct LibraryGridCell: View {

    /// 셀 높이를 **고정**하기 위한 치수. 제목 줄 수(1~2)·별점/날짜 유무에 따라 높이가 달라지면
    /// 그리드 행이 어긋나므로, 각 요소가 값 유무와 무관하게 같은 자리를 차지하게 한다.
    private enum Metric {
        static let thumbnailHeight: CGFloat = 160
        /// body4 2줄 (13 × 1.45 × 2 ≈ 37.7) — 제목은 항상 2줄만큼 자리를 잡는다.
        static let titleHeight: CGFloat = 38
        static let starSize: CGFloat = 9
        /// label2 1줄 (10 × 1.0).
        static let dateHeight: CGFloat = 10
    }

    let novel: LibraryNovel

    var body: some View {
        VStack(spacing: 0) {
            thumbnail
            Spacer().frame(height: 6)
            Text(novel.title)
                .applyWSSFont(.body4, color: .wssBlack, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: Metric.titleHeight, maxHeight: Metric.titleHeight, alignment: .topLeading)
            Spacer().frame(height: 2)
            starRow
            Spacer().frame(height: 4)
            dateRow
        }
    }

    /// 표지 — 좌하단 읽기 상태 뱃지, 우하단 관심 하트(표시 전용).
    private var thumbnail: some View {
        AsyncImage(url: novel.thumbnailImage) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.wssGray50
        }
        .frame(height: Metric.thumbnailHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // 잘린 그림 밖 원본 크기로 hit-test 영역이 남지 않게 명시(스크롤·셀 탭 간섭 예방).
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomLeading) {
            if let status = novel.userReview?.readingStatus {
                statusBadge(status)
                    .padding(.leading, 6)
                    .padding(.bottom, 8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if novel.isInterested {
                WSSImage.icHeartFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
            }
        }
    }

    private func statusBadge(_ status: ReadingStatus) -> some View {
        Text(status.statusName)
            .applyWSSFont(.label2, color: .wssWhite)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(status.tagBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 내 별점 5개 표기 — 0.5 단위 반별. (도메인 Rating은 0.5~5.0만 허용)
    /// 평점이 없어도 **자리는 유지**한다(셀 높이 고정).
    @ViewBuilder
    private var starRow: some View {
        if let rating = novel.userReview?.rating {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    starImage(at: index, rating: Float(rating.value))
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metric.starSize, height: Metric.starSize)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Metric.starSize, maxHeight: Metric.starSize, alignment: .leading)
        } else {
            Color.clear
                .frame(height: Metric.starSize)
        }
    }

    /// 독서 기간 — 없으면 빈 자리로 높이만 차지한다(셀 높이 고정).
    @ViewBuilder
    private var dateRow: some View {
        if let dateText = LibraryDateFormatter.text(for: novel.userReview?.period) {
            Text(dateText)
                .applyWSSFont(.label2, color: .wssGray200)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: Metric.dateHeight, maxHeight: Metric.dateHeight, alignment: .leading)
        } else {
            Color.clear
                .frame(height: Metric.dateHeight)
        }
    }

    private func starImage(at index: Int, rating: Float) -> Image {
        let position = Float(index)
        if rating >= position + 1 {
            return WSSImage.icSmallStarFilled.swiftUIImage
        } else if rating >= position + 0.5 {
            return WSSImage.icSmallStarHalf.swiftUIImage
        } else {
            return WSSImage.icSmallStarEmpty.swiftUIImage
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryGridCell(
        novel: LibraryNovel(
            id: NovelID(1),
            title: "당신의 이해를 돕기 위하여",
            thumbnailImage: nil,
            rating: 4.2,
            isInterested: true,
            userReview: UserNovelReview(
                readingStatus: .watching,
                rating: try? Rating(4.0),
                attractivePoint: [.character],
                period: nil,
                keywords: []
            ),
            writtenFeeds: []
        )
    )
    .frame(width: 108)
}
