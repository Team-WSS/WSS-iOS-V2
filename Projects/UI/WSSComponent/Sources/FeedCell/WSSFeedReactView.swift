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
    let likeButtonTapped: () -> Void
    
    public init(
        likeCount: Int,
        commentCount: Int,
        likeButtonTapped: @escaping () -> Void
    ) {
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.likeButtonTapped = likeButtonTapped
    }
}

//MARK: - Feed React 뷰

public struct WSSFeedReactView: View {
    
    let react: WSSFeedReact
    
    public var body: some View {
        HStack(spacing: 0) {
            WSSImage.icLike.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .onTapGesture {
                    react.likeButtonTapped()
                }
            
            Spacer().frame(width: 5)
                
            Text(String(react.likeCount))
                .applyWSSFont(.title3)
            
            Spacer().frame(width: 18)
            
            WSSImage.icComment.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
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
            commentCount: 12,
            likeButtonTapped: { print("좋아요 클릭") }
            )
    )
}
