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

public struct WSSFeedReactView: View {
    
    let likeCount: Int
    let commentCount: Int
    
    public init(
        likeCount: Int,
        commentCount: Int
    ) {
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            WSSImage.icLike.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Spacer().frame(width: 5)
                
            Text(String(likeCount))
                .applyWSSFont(.title3)
            
            Spacer().frame(width: 18)
            
            WSSImage.icComment.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Spacer().frame(width: 5)
                
            Text(String(commentCount))
                .applyWSSFont(.title3)
            
            Spacer()
                
        }
        .foregroundStyle(Color.wssGray200)
        .padding(.vertical, 8)
    }
}

#Preview {
    WSSFeedReactView(
        likeCount: 534,
        commentCount: 12
    )
}
