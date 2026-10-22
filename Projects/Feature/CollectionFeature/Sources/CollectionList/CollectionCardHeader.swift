//
//  CollectionCardHeader.swift
//  CollectionFeature
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

/// 컬렉션 카드 상단 — 제목(+ 우측 화살표)과 "설명 · 작품 N" 부제. 컬렉션 목록(`CollectionListView`)과
/// 전체 컬렉션뷰(`PublicCollectionListView`, #283)의 카드가 같은 헤더를 쓴다.
struct CollectionCardHeader: View {

    let name: String
    let description: String?
    let novelCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(name)
                    .applyWSSFont(.title2, color: .wssGray300)
                    .lineLimit(1)

                Spacer()

                WSSImage.icNavigateRight.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.wssGray300)
                    .frame(width: 24, height: 24)
            }

            subtitle
        }
    }

    private var subtitle: some View {
        HStack(spacing: 0) {
            if let description {
                Text(description)
                    .applyWSSFont(.label1, color: .wssGray300)
                    .lineLimit(1)

                Spacer().frame(width: 4)

                Circle()
                    .fill(Color.wssGray300)
                    .frame(width: 2, height: 2)

                Spacer().frame(width: 4)
            }

            HStack(spacing: 0) {
                Text("작품 ")
                    .applyWSSFont(.label1, color: .wssGray300)
                Text("\(novelCount)")
                    .applyWSSFont(.label1, color: .wssPrimary100)
            }

            Spacer().frame(width: 80)
        }
    }
}
