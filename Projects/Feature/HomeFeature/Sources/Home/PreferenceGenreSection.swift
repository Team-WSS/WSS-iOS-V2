//
//  PreferenceGenreSection.swift
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

/// "이 웹소설은 어때요?" — 선호장르 기반 추천 그리드.
/// 장르를 아직 고르지 않은 사용자는 목록 대신 **설정 유도 카드**를 본다(빈 상태가 아니라 별도 분기).
struct PreferenceGenreSection: View {

    let state: PreferenceGenreNovelState
    let onNovelSelected: (NovelID) -> Void
    let onSettingTapped: () -> Void

    private enum Metric {
        static let horizontalPadding: CGFloat = 20
        static let titleSpacing: CGFloat = 2
        static let sectionSpacing: CGFloat = 20

        static let columnSpacing: CGFloat = 9
        static let rowSpacing: CGFloat = 18
        static let coverAspectRatio: CGFloat = 163.0 / 241.0
        static let coverCornerRadius: CGFloat = 14
        static let coverToInfoSpacing: CGFloat = 6
        /// ⚠️ 제목이 1~2줄로 달라져 자연 높이로 두면 그리드 행이 어긋난다(LibraryFeature와 같은 함정).
        static let infoHeight: CGFloat = 72
        static let titleWidth: CGFloat = 140
        static let iconSize: CGFloat = 12

        static let emptyCardCornerRadius: CGFloat = 14
        static let emptyCardHorizontalPadding: CGFloat = 24
        static let emptyCardVerticalPadding: CGFloat = 20
        static let ctaCornerRadius: CGFloat = 8
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: Metric.columnSpacing),
         GridItem(.flexible(), spacing: Metric.columnSpacing)]
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionTitle
            Spacer().frame(height: Metric.sectionSpacing)

            switch state {
            case .novels(let novels):
                novelGrid(novels)
            case .noGenreSettings:
                settingInduceCard
            }
        }
    }
}

// MARK: - Sections

private extension PreferenceGenreSection {

    var sectionTitle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이 웹소설은 어때요? (´ヮ`)ﾉ📚")
                .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)

            Spacer().frame(height: Metric.titleSpacing)

            Text("선호장르를 기반으로 추천해드려요")
                .applyWSSFont(.body2, color: .wssGray200, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metric.horizontalPadding)
    }

    func novelGrid(_ novels: [PreferenceGenreNovel]) -> some View {
        LazyVGrid(columns: columns, spacing: Metric.rowSpacing) {
            ForEach(novels, id: \.novelID) { novel in
                novelCell(novel)
            }
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }

    func novelCell(_ novel: PreferenceGenreNovel) -> some View {
        Button {
            onNovelSelected(novel.novelID)
        } label: {
            VStack(spacing: 0) {
                // ⚠️ 비율은 **투명 뷰가 잡고 이미지는 overlay로 채운다**(LibraryGridCell 정본) —
                // `scaledToFill`인 이미지에 직접 `aspectRatio`를 걸면 둘이 충돌해 표지가 좁아진다(실측).
                Color.clear
                    .aspectRatio(Metric.coverAspectRatio, contentMode: .fit)
                    .overlay { WSSNovelCoverImage(url: novel.novelThumbnailImage) }
                    .clipShape(RoundedRectangle(cornerRadius: Metric.coverCornerRadius))
                    .contentShape(RoundedRectangle(cornerRadius: Metric.coverCornerRadius))

                Spacer().frame(height: Metric.coverToInfoSpacing)

                // 스택 안은 자연스럽게 흐르게 두고 스택 자체만 고정한다(제목 1줄이면 작가가 바로 따라온다).
                VStack(alignment: .leading, spacing: 0) {
                    countRow(novel)

                    // 제목 폭은 셀(163)이 아니라 **140**이라 두 줄로 꺾인다.
                    // ⚠️ 고정 `width`는 셀의 이상적 폭까지 끌어당겨 표지를 좁히므로 `maxWidth`로 제한하고,
                    // `fixedSize(vertical:)`로 세로 확장을 허용해야 말줄임 대신 실제로 꺾인다(실측).
                    Text(novel.novelTitle)
                        .applyWSSFont(.body4, color: .wssBlack, alignment: .leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: Metric.titleWidth, alignment: .leading)

                    Text(novel.novelAuthors.joined(separator: ", "))
                        .applyWSSFont(.body5, color: .wssGray200, alignment: .leading)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // 셀 전체 높이를 시안대로 **319**(표지 241 + 간격 6 + 정보 72)로 맞추는 마지막 조각.
                // 표지는 비율(163:241)이라 폭을 따라가고, 정보만 고정이라 행 높이가 어긋나지 않는다.
                .frame(height: Metric.infoHeight, alignment: .top)
            }
            .contentShape(Rectangle())
        }
    }

    func countRow(_ novel: PreferenceGenreNovel) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                WSSImage.icHeartFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSize, height: Metric.iconSize)

                Text("\(novel.interestCount)")
                    .applyWSSFont(.body5, color: .wssGray200)
            }

            HStack(spacing: 3) {
                // ⚠️ `icStarFilled`는 원색이 고정이라 그대로 쓰면 시안 색이 안 나온다 —
                // template으로 바꿔 secondary100을 입힌다(DesignSystem 규약).
                WSSImage.icStarFilled.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSize, height: Metric.iconSize)
                    .foregroundStyle(Color.wssSecondary100)

                Text("\(String(format: "%.1f", novel.rating)) (\(novel.ratingCount))")
                    .applyWSSFont(.body5, color: .wssGray200)
            }

            Spacer(minLength: 0)
        }
    }

    /// 선호장르 미설정 — 목록이 없는 게 아니라 "아직 고르지 않았다"라서 설정 화면으로 유도한다.
    var settingInduceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("로맨스, 로판, 판타지, 현판 등\n선호장르를 기반으로 웹소설을 추천해드려요!")
                .applyWSSFont(.body2, color: .wssGray200, alignment: .leading)

            Spacer().frame(height: 14)

            Button(action: onSettingTapped) {
                Text("선호장르 설정하기")
                    .applyWSSFont(.body3, color: .wssWhite)
                    .padding(.horizontal, 21)
                    .padding(.vertical, 6)
                    .background(Color.wssPrimary100)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.ctaCornerRadius))
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metric.emptyCardHorizontalPadding)
        .padding(.vertical, Metric.emptyCardVerticalPadding)
        .overlay {
            RoundedRectangle(cornerRadius: Metric.emptyCardCornerRadius)
                .strokeBorder(Color.wssGray70, lineWidth: 1)
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }
}
