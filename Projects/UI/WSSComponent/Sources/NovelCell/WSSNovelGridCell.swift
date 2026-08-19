//
//  WSSNovelGridCell.swift
//  WSSComponent
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 작품 그리드 셀 — 표지 위에 (관심 수·평점 / 제목 / 작가) 정보 스택을 붙인 2단 구성.
/// 정본: 홈 "이 웹소설은 어때요?" 그리드.
///
/// **폭은 부모가 정한다** — 그리드 열 너비(또는 호출부가 얹은 `.frame(width:)`)를 그대로 채우고,
/// 표지 높이는 `coverAspectRatio`로 정해진다. 표지와 텍스트가 **같은 폭을 공유**하므로
/// 폭을 어떻게 주든 좌우 정렬이 어긋나지 않는다.
public struct WSSNovelGridCell: View {

    /// 표지 기본 비율(디자인 163×241) — 폭을 따라가고 높이는 비율로 정해진다.
    /// `init`의 기본값이라 **public이어야 한다**(public 기본값은 private 상수를 참조할 수 없다).
    public static let defaultCoverAspectRatio: CGFloat = 163.0 / 241.0

    private enum Metric {
        static let coverCornerRadius: CGFloat = 14
        static let coverToInfoSpacing: CGFloat = 6
        /// ⚠️ 정보 스택의 **고정 높이**. 자연 높이로 두면 그리드 행이 어긋난다.
        /// 제목이 항상 1줄이라 `countRow(17.4) + title 1줄(18.85) + author(17.4) ≈ 54`로 맞춘 값 —
        /// 제목이 2줄까지 가던 시절의 72(#196 이전)를 그대로 두면 `LazyVGrid`의 `rowSpacing`과 별개로
        /// 셀 하단에 죽은 여백이 남아 행 간격이 의도보다 훨씬 넓어 보인다.
        static let infoHeight: CGFloat = 54
        static let iconSize: CGFloat = 12
        static let countSpacing: CGFloat = 8
        static let countIconSpacing: CGFloat = 3
    }

    private let thumbnailImage: URL?
    private let title: String
    private let author: String
    private let interestCount: Int
    private let rating: Float
    private let ratingCount: Int
    private let coverAspectRatio: CGFloat
    private let onTap: (() -> Void)?

    public init(
        thumbnailImage: URL?,
        title: String,
        author: String,
        interestCount: Int,
        rating: Float,
        ratingCount: Int,
        coverAspectRatio: CGFloat = WSSNovelGridCell.defaultCoverAspectRatio,
        onTap: (() -> Void)? = nil
    ) {
        self.thumbnailImage = thumbnailImage
        self.title = title
        self.author = author
        self.interestCount = interestCount
        self.rating = rating
        self.ratingCount = ratingCount
        self.coverAspectRatio = coverAspectRatio
        self.onTap = onTap
    }

    public var body: some View {
        // 탭이 필요 없는 자리(전시·플레이스홀더)도 있어 콜백은 옵셔널 — 없으면 순수 표시 뷰로 둔다.
        if let onTap {
            Button(action: onTap) { cell }
        } else {
            cell
        }
    }
}

// MARK: - Sections

private extension WSSNovelGridCell {

    var cell: some View {
        VStack(spacing: 0) {
            cover

            Spacer().frame(height: Metric.coverToInfoSpacing)

            infoStack
        }
        .contentShape(Rectangle())
    }

    /// 비율은 표지 컴포넌트에 **파라미터로** 넘긴다 — 밖에서 `.aspectRatio`를 걸면 `scaledToFill`과
    /// 충돌해 표지가 좁아진다(그래서 `WSSNovelCoverImage`가 비율을 직접 받는다).
    var cover: some View {
        WSSNovelCoverImage(url: thumbnailImage, aspectRatio: coverAspectRatio)
            .clipShape(RoundedRectangle(cornerRadius: Metric.coverCornerRadius))
            // 잘린 그림 밖 원본 크기로 hit-test 영역이 남지 않게 명시(스크롤·셀 탭 간섭 예방).
            .contentShape(RoundedRectangle(cornerRadius: Metric.coverCornerRadius))
    }

    /// 스택 **안은 자연스럽게 흐르게** 두고 스택 **자체만** 고정한다(제목이 1줄이면 작가가 바로 따라온다).
    var infoStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            countRow

            Text(title)
                .applyWSSFont(.body4, color: .wssBlack, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(author)
                .applyWSSFont(.body5, color: .wssGray200, alignment: .leading)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // ⚠️ `.frame(maxWidth:height:)` 오버로드는 없다 — 두 번 나눠 건다.
        .frame(height: Metric.infoHeight, alignment: .top)
    }

    var countRow: some View {
        HStack(spacing: Metric.countSpacing) {
            HStack(spacing: Metric.countIconSpacing) {
                WSSImage.icHeartFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSize, height: Metric.iconSize)

                Text("\(interestCount)")
                    .applyWSSFont(.body5, color: .wssGray200)
            }

            HStack(spacing: Metric.countIconSpacing) {
                // ⚠️ `icStarFilled`는 원색이 고정이라 그대로 쓰면 디자인 색이 안 나온다 —
                // template으로 바꿔 secondary100을 입힌다(DesignSystem 규약).
                WSSImage.icStarFilled.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSize, height: Metric.iconSize)
                    .foregroundStyle(Color.wssSecondary100)

                Text("\(String(format: "%.1f", rating)) (\(ratingCount))")
                    .applyWSSFont(.body5, color: .wssGray200)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)],
        spacing: 18
    ) {
        WSSNovelGridCell(
            thumbnailImage: nil,
            title: "신데렐라는 이 멧밭쥐가 데려갑니다",
            author: "이보라",
            interestCount: 23,
            rating: 4.0,
            ratingCount: 2
        ) {}

        WSSNovelGridCell(
            thumbnailImage: nil,
            title: "한 줄 제목",
            author: "김작가, 이작가",
            interestCount: 1204,
            rating: 4.5,
            ratingCount: 128
        ) {}
    }
    .padding(.horizontal, 20)
}
