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

    private enum Metric {
        /// 표지 비율(디자인 108×160) — 폭은 그리드 열 너비를 따라가고 높이는 비율로 정해진다.
        static let thumbnailAspectRatio: CGFloat = 108.0 / 160.0
        /// 표지 아래 정보 스택의 **고정 높이**(제목 2줄 + 별점 + 날짜를 담는 크기).
        /// 제목 줄 수·별점/날짜 유무로 높이가 흔들리면 그리드 행이 어긋나므로 값에 상관없이 고정한다.
        static let infoHeight: CGFloat = 65
        static let starSize: CGFloat = 9
        static let statusBadgeWidth: CGFloat = 49
    }

    let novel: LibraryNovel

    var body: some View {
        VStack(spacing: 0) {
            thumbnail
            Spacer().frame(height: 6)
            infoStack
        }
    }

    /// 제목·별점·날짜. 내용은 자연스럽게 위에서부터 흐르고, 스택 자체만 고정 높이를 차지한다.
    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(novel.title)
                .applyWSSFont(.body4, color: .wssBlack, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let rating = novel.userReview?.rating {
                Spacer().frame(height: 2)
                starRow(rating: Float(rating.value))
            }
            if let dateText = LibraryDateFormatter.text(for: novel.userReview?.period) {
                Spacer().frame(height: 4)
                Text(dateText)
                    .applyWSSFont(.label2, color: .wssGray200)
                    .lineLimit(1)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Metric.infoHeight,
            maxHeight: Metric.infoHeight,
            alignment: .topLeading
        )
    }

    /// 표지 — 열 너비에 맞춰 비율(108:160)대로 커지고, 좌하단 읽기 상태 뱃지·우하단 관심 하트를 얹는다.
    /// 표지 로드·캐시·빈 표지 폴백은 `WSSNovelCoverImage`가 담당(토글·재활용 시 번쩍임 방지).
    private var thumbnail: some View {
        Color.clear
            .aspectRatio(Metric.thumbnailAspectRatio, contentMode: .fit)
            .overlay {
                WSSNovelCoverImage(url: novel.thumbnailImage)
            }
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
                WSSImage.icHeartFilledStroke.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .padding(.trailing, 9.5)
                    .padding(.bottom, 9.5)
            }
        }
    }

    private func statusBadge(_ status: ReadingStatus) -> some View {
        Text(status.statusName)
            .applyWSSFont(.label2, color: .wssWhite)
            .frame(width: Metric.statusBadgeWidth)
            .padding(.vertical, 4)
            .background(status.tagBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 내 별점 5개 표기 — 0.5 단위 반별. (도메인 Rating은 0.5~5.0만 허용)
    private func starRow(rating: Float) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                starImage(at: index, rating: rating)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.starSize, height: Metric.starSize)
            }
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
