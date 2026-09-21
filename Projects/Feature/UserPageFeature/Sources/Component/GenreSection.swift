//
//  GenreSection.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent
import ProfileDomain

/// MyPage·UserPage 공용 장르 뱃지 섹션. 대표 3개는 항상 노출, 나머지는 펼침 토글로 노출한다.
/// 펼침 상태는 화면 전환마다 초기화되면 되는 순수 UI 상태라 컴포넌트가 직접 소유한다.
/// 데이터가 비어있는 경우의 노출 여부는 호출부(화면)가 판단한다.
struct GenreSection: View {

    let genrePreferences: [GenrePreference]
    var showGenreBadgeText: Bool = true
    
    @State private var isExpanded = false

    private var totalBadgeCount: Int {
        genrePreferences.reduce(0) { $0 + $1.count }
    }

    private var topGenrePreferences: [GenrePreference] {
        Array(genrePreferences.prefix(3))
    }

    private var remainingGenrePreferences: [GenrePreference] {
        Array(genrePreferences.dropFirst(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            if showGenreBadgeText {
                HStack(spacing: 0) {
                    Text("\(totalBadgeCount)")
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                    Text("개의 장르 뱃지")
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    
                    Spacer()
                }
                .applyWSSFont(.title2)
                .padding(.vertical, 10)
                
                Spacer().frame(height: 9)
            }

            HStack(spacing: 0) {
                ForEach(topGenrePreferences, id: \.genre) { preference in
                    representativeGenreItem(preference: preference)
                }
            }

            if isExpanded {
                Spacer().frame(height: 20)

                VStack(spacing: 2) {
                    ForEach(remainingGenrePreferences, id: \.genre) { preference in
                        genreItemRow(preference: preference)
                    }
                }
                .transition(.opacity)
            }

            Spacer().frame(height: 6)

            if !remainingGenrePreferences.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    WSSImage.icDropdownsmall.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(nil, value: isExpanded)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func representativeGenreItem(preference: GenrePreference) -> some View {
        VStack(spacing: 0) {
            preference.genre.iconImage
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)

            Spacer().frame(height: 11)

            Text(preference.genre.displayName)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(height: 2)

            Text("\(preference.count)개")
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func genreItemRow(preference: GenrePreference) -> some View {
        HStack(spacing: 0) {
            preference.genre.iconImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Spacer().frame(width: 21)

            Text(preference.genre.displayName)
                .applyWSSFont(.body3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer()

            Text("\(preference.count)개")
                .applyWSSFont(.body3)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
                .padding(.trailing, 20)
        }
        .frame(height: 40)
        .padding(.horizontal, 13)
    }
}
