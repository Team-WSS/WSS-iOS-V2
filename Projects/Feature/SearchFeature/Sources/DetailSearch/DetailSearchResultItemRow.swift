//
//  DetailSearchResultItemRow.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain

import DesignSystem
import WSSComponent

struct DetailSearchResultItemRow: View {
    let novel: Novel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: novel.thumbnailImage,
                       transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                case .failure(_):
                    WSSImage.imgEmpty.swiftUIImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    ProgressView()
                }
            }
            .frame(minWidth: 163, maxWidth: .infinity)
            .frame(height: 241)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            Spacer().frame(height: 6)
            
            HStack(alignment: .center, spacing: 0) {
                WSSImage.icHeartFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 8)

                Spacer().frame(width: 3)

                Text("\(novel.interestCount)")
                    .applyWSSFont(.body5)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

                Spacer().frame(width: 9.5)

                WSSImage.icSmallStarFilled.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 8)

                Spacer().frame(width: 5)

                Text(String(format: "%.1f (%d)", novel.rating, novel.ratingCount))
                    .applyWSSFont(.body5)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            
            Text(novel.title)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .lineLimit(1)

            Text(novel.authors.joined(separator: ", "))
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DetailSearchResultItemRow(novel: Novel(id: NovelID(1),
                                           thumbnailImage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg"),
                                           title: "미리보기 작품 미리보기  미리보기  미리보기 작품 미리보기 작품",
                                           authors: ["프리뷰 작가프리뷰 작가프리뷰 작가프리뷰 작가프리뷰 작가프리뷰 작가"],
                                           genres: [],
                                           interestCount: 8,
                                           rating: 4.9,
                                           ratingCount: 2,
                                           isInterested: false)
         )
         .frame(width: 200)
         .background(WSSColor.wssGray20.swiftUIColor)
}
