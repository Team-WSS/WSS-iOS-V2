//
//  HomeSearchSection.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 검색바 + 상세검색 유도 배너. 둘 다 데이터와 무관한 고정 진입점이라 한 뷰로 묶는다.
/// ⚠️ 좌우 여백이 20이 아니라 **13**이다 — 아래 추천 섹션들(20)보다 좁은 게 디자인이다.
struct HomeSearchSection: View {

    let onSearchTapped: () -> Void
    let onDetailSearchTapped: () -> Void

    private enum Metric {
        static let horizontalPadding: CGFloat = 13
        static let spacing: CGFloat = 20

        static let searchBarHeight: CGFloat = 49
        static let searchIconSize: CGFloat = 25
        static let cornerRadius: CGFloat = 14

        static let bannerHeight: CGFloat = 104
        static let bannerTextLeading: CGFloat = 20
        static let bannerArrowSize: CGFloat = 24
        static let bannerImageWidth: CGFloat = 113
        static let bannerImageHeight: CGFloat = 91
        static let bannerImageTop: CGFloat = 36
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Spacer().frame(height: Metric.spacing)
            detailSearchBanner
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }
}

// MARK: - Sections

private extension HomeSearchSection {

    /// 입력이 아니라 **검색 화면으로 가는 버튼**이다(여기서 타이핑하지 않는다).
    var searchBar: some View {
        Button(action: onSearchTapped) {
            HStack(spacing: 0) {
                Text("작품 제목, 작가를 검색하세요")
                    .applyWSSFont(.body4, color: .wssGray200, alignment: .leading)

                Spacer()

                WSSImage.icSearch.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.searchIconSize, height: Metric.searchIconSize)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(height: Metric.searchBarHeight)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .contentShape(Rectangle())
        }
    }

    var detailSearchBanner: some View {
        Button(action: onDetailSearchTapped) {
            ZStack(alignment: .leading) {
                Color.wssPrimary20

                // 일러스트는 배너 오른쪽에 붙어 아래가 잘린다(카드가 클립).
                HStack(spacing: 0) {
                    Spacer()
                    WSSImage.imgSearchCat.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metric.bannerImageWidth,
                               height: Metric.bannerImageHeight)
                        .padding(.top, Metric.bannerImageTop)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("뭐 읽을지 고민될 때")
                            .applyWSSFont(.title1, color: .wssBlack, alignment: .leading)

                        WSSImage.icNavigateRight.swiftUIImage
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                            .scaledToFit()
                            .frame(width: Metric.bannerArrowSize,
                                   height: Metric.bannerArrowSize)
                    }

                    Spacer().frame(height: 4)

                    Text("장르, 연재상태, 별점, 키워드로 작품 찾기")
                        .applyWSSFont(.body4, color: .wssGray200, alignment: .leading)
                    
                    Spacer().frame(height: 8)
                }
                .padding(.leading, Metric.bannerTextLeading)
            }
            .frame(height: Metric.bannerHeight)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    HomeSearchSection(onSearchTapped: {},
                      onDetailSearchTapped: {})
}
