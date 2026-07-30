//
//  CommentRow.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

struct CommentRow: View {
    
    let userID: Int
    let profileImageURL: URL?
    let username: String
    let content: String
    let createdAt: String
    let isEdited: Bool
    let myComment: Bool
    let threeDotsAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                if !myComment {
                    print("\(userID) 유저페이지로 이동")
                }
            } label: {
                AsyncImage(url: profileImageURL) {
                    phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                    case .failure:
                        WSSImage.imgLoadingThumbnail.swiftUIImage
                    default:
                        ProgressView()
                    }
                }
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            Spacer().frame(width: 14)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Text(username)
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
                
                Text(content)
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
            
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

#Preview {
    CommentRow(
        userID: 1,
        profileImageURL: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
        username: "구리구리스",
        content: "댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..댓글입니다.. 댓글 내용입니다..하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하하",
        createdAt: "10월 3일",
        isEdited: true,
        myComment: true,
        threeDotsAction: { print("드롭다운 클릭") }
    )
}
