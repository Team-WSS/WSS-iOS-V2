//
//  WSSFeedReactView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

//MARK: - Feed React 구조체

public struct WSSFeedReact {
    
    let likeCount: Int
    let commentCount: Int
    
    public init(
        likeCount: Int,
        commentCount: Int,
    ) {
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}

//MARK: - Feed React 뷰

public struct WSSFeedReactView: View {
    
    let react: WSSFeedReact
    
    let isLiked: Bool
    let likeButtonTapped: () -> Void
    
    public init(
        react: WSSFeedReact,
        isLiked: Bool,
        likeButtonTapped: @escaping () -> Void
    ) {
        self.react = react
        self.isLiked = isLiked
        self.likeButtonTapped = likeButtonTapped
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            Button {
                likeButtonTapped()
            } label: {
                if isLiked {
                    WSSImage.icLikeSelected.swiftUIImage
                        .frame(width: 20, height: 20)
                } else {
                    WSSImage.icLike.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                        .frame(width: 20, height: 20)
                }
            }
            
            Spacer().frame(width: 5)
                
            Text(String(react.likeCount))
                .applyWSSFont(.title3)
            
            Spacer().frame(width: 18)
            
            WSSImage.icComment.swiftUIImage
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .frame(width: 20, height: 20)
            
            Spacer().frame(width: 5)
                
            Text(String(react.commentCount))
                .applyWSSFont(.title3)
            
            Spacer()
                
        }
        .foregroundStyle(Color.wssGray200)
        .padding(.vertical, 8)
    }
}

#Preview {
    WSSFeedReactView(
        react: WSSFeedReact(
            likeCount: 534,
            commentCount: 12
            ),
        isLiked: true,
        likeButtonTapped: { print("좋아요 클릭") }
    )
}
