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

    let novel: LibraryNovel

    var body: some View {
        VStack(spacing: 0) {
            thumbnail
            Spacer().frame(height: 6)
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 표지 — 좌하단 읽기 상태 뱃지, 우하단 관심 하트(표시 전용).
    private var thumbnail: some View {
        AsyncImage(url: novel.thumbnailImage) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.wssGray50
        }
        .frame(height: 160)
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
    private func starRow(rating: Float) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                starImage(at: index, rating: rating)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.bottom, 4)
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
