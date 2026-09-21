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
        commentCount: Int
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
            // 실제 `Button`이어야 셀 행 컨테이너의 `onTapGesture`(피드 상세 진입)보다 이 영역이 우선한다
            // (WSSFeadHeaderView 프로필 버튼과 동일 이유 — WSSComponent/CLAUDE.md 참고).
            Button(action: likeButtonTapped) {
                // 눌린 상태는 채움 아이콘 + 검정 — 미설정 시 기본 크로스페이드가 느리게 번져 짧은 명시 애니메이션을 건다.
                (isLiked ? WSSImage.icThumbUpFill : WSSImage.icThumbUp).swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(isLiked ? Color.wssBlack : Color.wssGray200)
                    .animation(.easeInOut(duration: 0.1), value: isLiked)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("좋아요")

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
            commentCount: 12
        ),
        isLiked: true,
        likeButtonTapped: { print("좋아요 클릭") }
    )
}
