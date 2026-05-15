//
//  LinkNovelView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem
import BaseDomain

// MARK: - Link Novel 구조체

public struct WSSLinkNovel {
    public let genreType: NovelGenre
    public let novelTitle: String
    public let novelRating: Float

    public init(
        genreType: NovelGenre,
        novelTitle: String,
        novelRating: Float
    ) {
        self.genreType = genreType
        self.novelTitle = novelTitle
        self.novelRating = novelRating
    }
}

// MARK: - Link Novel 뷰

public struct WSSLinkNovelView: View {
    
    let genreType: NovelGenre
    let novelTitle: String
    let novelRating: Float
    
    public init(
        genreType: NovelGenre,
        novelTitle: String,
        novelRating: Float
    ) {
        self.genreType = genreType
        self.novelTitle = novelTitle
        self.novelRating = novelRating
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            WSSImage.icGenreLink.swiftUIImage
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(genreType.linkColor)
                .padding(.trailing, 6)
            
            Text(novelTitle)
                .applyWSSFont(.title3)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(1)
            
            Spacer(minLength: 60)
            
            WSSImage.icSmallStarEmpty.swiftUIImage
                .renderingMode(.template)
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.wssGray200)
                .padding(.trailing, 5)
            
            
            Text(String(novelRating))
                .applyWSSFont(.label1)
                .foregroundStyle(Color.wssBlack)
                .padding(.trailing, 6)
            
            WSSImage.icNavigateRight.swiftUIImage
                .renderingMode(.template)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.wssGray100)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(genreType.blockColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    VStack {
        WSSLinkNovelView(
            genreType: .lightNovel,
            novelTitle: "스즈미야 하루히의 무료",
            novelRating: 4.3
        )
    }
}
