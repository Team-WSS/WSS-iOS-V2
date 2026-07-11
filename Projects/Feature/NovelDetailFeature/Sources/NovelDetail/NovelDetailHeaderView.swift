//
//  NovelDetailHeaderView.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

/// 몰입형 헤더: 블러 커버 배경 + 표지(장르 마크) + 제목·메타·카운트.
/// `novel`은 관심 토글이 반영되는 값이라 `information.novel` 대신 따로 받는다.
struct NovelDetailHeaderView: View {

    let information: NovelInformation
    let novel: Novel

    var body: some View {
        VStack(spacing: 0) {
            // 커버 top 99 = 디자인 고정 영역(status bar 54 + nav 44) 아래
            Spacer().frame(height: 99)
            coverImage
            Spacer().frame(height: 20)
            titleBlock
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { backdrop }
    }

    // MARK: - Backdrop

    /// 상단 330pt: 커버를 크게 깔고 블러 + 밝은 보라 틴트 → 아래 회색(wssGray50) 영역으로 자연 연결.
    /// 디자인의 radial gradient(#F4F5F8→#D2D3F7)는 디자인 시스템 토큰(wssPrimary20/wssGray50) 조합으로 근사.
    private var backdrop: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.wssPrimary20
                AsyncImage(url: novel.thumbnailImage) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 330, alignment: .top)
                .clipped()
                .blur(radius: 12, opaque: true)

                WSSImage.imgDetailBackgroundGradation.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 330)
                    .clipped()
            }
            .frame(height: 330)
            .clipped()

            Color.wssGray50
        }
    }

    // MARK: - Cover

    private var coverImage: some View {
        AsyncImage(url: novel.thumbnailImage) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                WSSImage.imgLoadingThumbnail.swiftUIImage
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 148, height: 217)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.wssBlack.opacity(0.1), radius: 15, x: 0, y: 2)
        // 장르 마크는 표지 우하단 모서리에 정렬(디자인 좌표: 표지 bottom/trailing 일치)
        .overlay(alignment: .bottomTrailing) {
            if let genre = information.genres.first {
                genreMark(genre)
            }
        }
    }

    /// 우하단 코너 라벨: 흰 코너 삼각형 배경(icGenreBackground, 71pt)의 우하단에
    /// 장르 아이콘(iconImage, 32pt)을 trailing 4 / bottom 5 인셋으로 얹는다. (V1 레이아웃 그대로)
    private func genreMark(_ genre: NovelGenre) -> some View {
        WSSImage.icGenreBackground.swiftUIImage
            .resizable()
            .frame(width: 71, height: 71)
            .overlay(alignment: .bottomTrailing) {
                genre.iconImage
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(.trailing, 4)
                    .padding(.bottom, 5)
            }
    }

    // MARK: - Title / Meta / Counts

    private var titleBlock: some View {
        VStack(spacing: 0) {
            Text(novel.title)
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
            Spacer().frame(height: 6)
            Text(metaText)
                .applyWSSFont(.body3)
                .foregroundStyle(Color.wssGray200)
            Spacer().frame(height: 6)
            countsRow
        }
    }

    /// "로판/로맨스  ·  완결작  ·  이보라" — 장르 나열 / 연재 상태 / 작가.
    private var metaText: String {
        var parts: [String] = []
        if !information.genres.isEmpty {
            parts.append(information.genres.map(\.displayName).joined(separator: "/"))
        }
        parts.append(publicationStatusName)
        if !novel.authors.isEmpty {
            parts.append(novel.authors.joined(separator: ", "))
        }
        return parts.joined(separator: "  ·  ")
    }

    /// NovelPublicationStatus는 NovelDomain 타입이라 WSSComponent(DomainPresentation)에 못 두고 여기서 매핑한다.
    private var publicationStatusName: String {
        switch information.publicationStatus {
        case .onGoing:   "연재작"
        case .completed: "완결작"
        }
    }

    private var countsRow: some View {
        HStack(spacing: 0) {
            countItem(icon: WSSImage.icCountInterest.swiftUIImage, text: "\(novel.interestCount)")
            Spacer().frame(width: 20)
            countItem(icon: WSSImage.icCountRating.swiftUIImage,
                      text: String(format: "%.1f (%d)", novel.rating, novel.ratingCount))
            Spacer().frame(width: 20)
            countItem(icon: WSSImage.icCountFeed.swiftUIImage, text: "\(information.feedCount)")
        }
    }

    private func countItem(icon: Image, text: String) -> some View {
        HStack(spacing: 0) {
            icon
                .resizable()
                .frame(width: 14, height: 14)
            Spacer().frame(width: 5)
            Text(text)
                .applyWSSFont(.body5_2)
                .foregroundStyle(Color.wssGray300)
        }
    }
}
