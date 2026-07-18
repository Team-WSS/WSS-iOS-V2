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
    /// 내가 좋아요를 눌렀는지 — 아이콘이 외곽선(icThumbUp) ↔ 채움(icThumbUpFill)으로 갈린다.
    let isLiked: Bool
    let commentCount: Int
    let likeButtonTapped: () -> Void

    public init(
        likeCount: Int,
        isLiked: Bool,
        commentCount: Int,
        likeButtonTapped: @escaping () -> Void
    ) {
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.commentCount = commentCount
        self.likeButtonTapped = likeButtonTapped
    }
}

//MARK: - Feed React 뷰

public struct WSSFeedReactView: View {
    
    let react: WSSFeedReact
    
    public var body: some View {
        HStack(spacing: 0) {
            // 눌린 상태는 채움 아이콘 + 검정 — 미설정 시 기본 크로스페이드가 느리게 번져 짧은 명시 애니메이션을 건다.
            (react.isLiked ? WSSImage.icThumbUpFill : WSSImage.icThumbUp).swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(react.isLiked ? Color.wssBlack : Color.wssGray200)
                .animation(.easeInOut(duration: 0.1), value: react.isLiked)
                .onTapGesture {
                    react.likeButtonTapped()
                }
                // 순수 이미지 + 제스처라 접근성 트리에 안 잡힌다 — 버튼으로 인식하게 한다.
                .accessibilityLabel("좋아요")
                .accessibilityAddTraits(.isButton)
            
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
            isLiked: true,
            commentCount: 12,
            likeButtonTapped: { print("좋아요 클릭") }
            )
    )
}
