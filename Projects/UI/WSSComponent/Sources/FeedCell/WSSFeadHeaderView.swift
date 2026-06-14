//
//  WSSFeadHeaderView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

//MARK: - Feed Header 구조체

public struct FeedHeader {
    public let profileImageURL: URL?
    public let nickname: String
    public let createdDate: String
    public let isEdited: Bool

    public init(
        profileImageURL: URL?,
        nickname: String,
        createdDate: String,
        isEdited: Bool
    ) {
        self.profileImageURL = profileImageURL
        self.nickname = nickname
        self.createdDate = createdDate
        self.isEdited = isEdited
    }
}

// MARK: - Feed Header 뷰

public struct WSSFeadHeaderView: View {

    let header: FeedHeader
    
    public let profileImageTapped: () -> Void
    public let showThreeDotsButton: Bool
    public let threeDotsButtonTapped: () -> Void
    
    public init(
        header: FeedHeader,
        profileImageTapped: @escaping () -> Void,
        showThreeDotsButton: Bool = true,
        threeDotsButtonTapped: @escaping () -> Void = { }
    ) {
        self.header = header
        self.profileImageTapped = profileImageTapped
        self.showThreeDotsButton = showThreeDotsButton
        self.threeDotsButtonTapped = threeDotsButtonTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button {
                profileImageTapped()
            } label: {
                AsyncImage(url: header.profileImageURL) {
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
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer().frame(width: 10)

            Text(header.nickname)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
            
            Spacer().frame(width: 4)
            
            Circle()
                .frame(width: 2, height: 2)
                .foregroundColor(Color.wssGray200)
                .frame(width: 8, height: 8)
            
            Spacer().frame(width: 4)
            
            Text(header.createdDate)
                .applyWSSFont(.body5)
                .foregroundStyle(Color.wssGray200)
            
            Spacer().frame(width: 4)
            
            if (header.isEdited) {
                Text("(수정됨)")
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
            }
            
            Spacer()
            
            if showThreeDotsButton {
                Button {
                    threeDotsButtonTapped()
                } label: {
                    WSSImage.icThreedots.swiftUIImage
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 32, height: 32, alignment: .trailing)
                }
            }
        }
        .background(Color.wssWhite)
    }
}

#Preview {
    WSSFeadHeaderView(
        header: FeedHeader(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
            nickname: "구리스",
            createdDate: "2024년 6월 19일",
            isEdited: true
        ),
        profileImageTapped: { }
    )
}
