//
//  KeywordSection.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent
import ProfileDomain

/// MyPage·UserPage 공용 작품 취향(매력 포인트 + 키워드) 섹션.
/// "데이터 없음" 여부는 장르 취향 등 이 컴포넌트가 모르는 값과도 얽인 화면별 판단이라 호출부가 결정해 넘긴다.
struct KeywordSection: View {

    let hasNoData: Bool
    let attractivePointsText: String
    let keywordPreferences: [KeywordPreference]

    var body: some View {
        VStack(spacing: 0) {
            if hasNoData {
                preferenceNodataSection
            } else {
                Spacer().frame(height: 20)

                HStack(spacing: 0) {
                    Text(attractivePointsText)
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                    Text("(이)가 매력적인 작품이에요.")
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                }
                .frame(maxWidth: .infinity)
                .applyWSSFont(.title3)
                .padding(.vertical, 14.5)
                .background(WSSColor.wssGray50.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer().frame(height: 20)

                WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    ForEach(keywordPreferences, id: \.keyword.id) { item in
                        CountedKeywordChip(keyword: item.keyword.name,
                                           count: item.count)
                    }
                }
            }
        }
        .padding([.horizontal, .bottom], 20)
    }

    private var preferenceNodataSection: some View {
        VStack(spacing: 20) {
            WSSImage.imgEmptyCatQuestionmark.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 166)

            Text("작품 취향을 파악할 수 없어요")
                .applyWSSFont(.body2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
