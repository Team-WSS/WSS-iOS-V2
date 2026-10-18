//
//  PublicCollectionSection.swift
//  HomeFeature
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import DesignSystem
import WSSComponent

/// "컬렉션 모음.zip" — 모든 사용자의 공개 컬렉션을 최신순(왼쪽이 최신) 가로 스크롤로 최대 10개 보여준다(#283).
/// 제목 줄 탭은 전체 컬렉션뷰, 카드 탭은 컬렉션 상세로 간다.
struct PublicCollectionSection: View {

    let collections: [PublicCollectionCard]
    let onTitleTapped: () -> Void
    let onCollectionSelected: (CollectionID) -> Void

    private enum Metric {
        static let horizontalPadding: CGFloat = 20
        static let titleToCards: CGFloat = 14
        static let cardSpacing: CGFloat = 12

        static let cardWidth: CGFloat = 284
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 14
        static let headerToCovers: CGFloat = 16
        static let coversToOwner: CGFloat = 16
        static let subtitleSpacing: CGFloat = 4
        static let coverSlotCount = 4
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionTitle
            Spacer().frame(height: Metric.titleToCards)
            cards
        }
    }
}

// MARK: - Sections

private extension PublicCollectionSection {

    var sectionTitle: some View {
        Button(action: onTitleTapped) {
            HStack(spacing: 0) {
                Text("컬렉션 모음.zip")
                    .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)
                    .lineLimit(1)

                Spacer()

                WSSImage.icNavigateRight.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Metric.horizontalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var cards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Metric.cardSpacing) {
                ForEach(collections, id: \.id) { collection in
                    card(collection)
                }
            }
            .padding(.horizontal, Metric.horizontalPadding)
        }
    }

    func card(_ collection: PublicCollectionCard) -> some View {
        Button {
            onCollectionSelected(collection.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(collection.name)
                    .applyWSSFont(.title2, color: .wssGray300, alignment: .leading)
                    .lineLimit(1)

                Spacer().frame(height: Metric.subtitleSpacing)

                subtitle(collection)

                Spacer().frame(height: Metric.headerToCovers)

                WSSCollectionCoverStack(
                    coverURLs: collection.recentNovels.map(\.thumbnailImage),
                    slotCount: Metric.coverSlotCount
                )

                Spacer().frame(height: Metric.coversToOwner)

                WSSCollectionOwnerLabel(
                    nickname: collection.owner.nickname,
                    profileImage: collection.owner.profileImage
                )
            }
            .padding(Metric.cardPadding)
            .frame(width: Metric.cardWidth, alignment: .leading)
            .background(Color.wssPrimary20)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cardCornerRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// "설명 · 작품 N". 설명이 없으면 "작품 N"만 남는다. 설명이 길면 설명만 말줄임되고 작품 수는 지킨다.
    func subtitle(_ collection: PublicCollectionCard) -> some View {
        HStack(spacing: 0) {
            if let description = collection.description {
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
                Text("\(collection.novelCount)")
                    .applyWSSFont(.label1, color: .wssPrimary100)
            }
            .fixedSize()
        }
    }
}
