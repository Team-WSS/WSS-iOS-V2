//
//  CommentRow.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CommentDomain
import DesignSystem
import WSSComponent

struct CommentRow: View {

    let profileImageURL: URL?
    let username: String
    let content: String
    let createdAt: String
    let isEdited: Bool
    let visibility: CommentVisibility
    let myComment: Bool
    /// 프로필 탭 → 유저 프로필 진입 콜백. 내 댓글이거나 차단/숨김 처리된 댓글이면 아예 부르지 않는다
    /// (아래 Button 액션의 가드) — 실제 이동 여부(탈퇴 유저 판정 등)는 호출자(`FeedDetailView`)가
    /// `Author.accessibleUserId`로 판단한다. 이 컴포넌트는 Domain 타입을 모른다.
    let profileImageTapped: () -> Void
    let threeDotsAction: () -> Void

    @State private var isSpoilerRevealed: Bool = false

    private var displayedUsername: String {
        visibility == .blocked ? "차단한 유저" : username
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                // 내 댓글이거나 차단/숨김 처리된 댓글이면 프로필로 이동하지 않는다 — 숨김/차단
                // 상태에선 닉네임 자체가 "차단한 유저"로 가려져 나오므로 탭도 막는다(사용자 확정).
                guard !myComment, visibility == .visible || visibility == .spoiler else { return }
                profileImageTapped()
            } label: {
                WSSProfileImage(url: profileImageURL)
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Spacer().frame(width: 14)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Text(displayedUsername)
                        .applyWSSFont(.title3)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                    Circle()
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                        .frame(width: 2, height: 2)

                    Text(createdAt)
                        .applyWSSFont(.body5)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

                    if isEdited {
                        Text("(수정됨)")
                            .applyWSSFont(.body5)
                            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    }
                }

                switch visibility {
                case .blocked:
                    Text("차단된 유저의 댓글")
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                case .hidden:
                    Text("숨김 처리된 댓글")
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                case .spoiler where !isSpoilerRevealed:
                    Button {
                        isSpoilerRevealed = true
                    } label: {
                        Text("스포일러가 포함된 댓글 보기")
                            .applyWSSFont(.body2)
                            .foregroundStyle(WSSColor.wssSecondary100.swiftUIColor)
                    }
                case .spoiler, .visible:
                    Text(content)
                        .applyWSSFont(.body2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            if visibility != .blocked && visibility != .hidden {
                Button {
                    threeDotsAction()
                } label: {
                    WSSImage.icThreedots.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack {
        CommentRow(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
            username: "구리구리스",
            content: "댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하",
            createdAt: "10월 3일",
            isEdited: true,
            visibility: .spoiler,
            myComment: true,
            profileImageTapped: { print("유저 페이지로 이동") },
            threeDotsAction: { print("드롭다운 클릭") }
        )

        CommentRow(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
            username: "구리구리스",
            content: "댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하",
            createdAt: "10월 3일",
            isEdited: true,
            visibility: .visible,
            myComment: true,
            profileImageTapped: { print("유저 페이지로 이동") },
            threeDotsAction: { print("드롭다운 클릭") }
        )

        CommentRow(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
            username: "구리구리스",
            content: "숨겨진 댓글 내용",
            createdAt: "10월 3일",
            isEdited: false,
            visibility: .hidden,
            myComment: false,
            profileImageTapped: { print("유저 페이지로 이동") },
            threeDotsAction: { print("드롭다운 클릭") }
        )

        CommentRow(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
            username: "구리구리스",
            content: "차단된 유저의 댓글 내용",
            createdAt: "10월 3일",
            isEdited: false,
            visibility: .blocked,
            myComment: false,
            profileImageTapped: { print("유저 페이지로 이동") },
            threeDotsAction: { print("드롭다운 클릭") }
        )
    }
}
