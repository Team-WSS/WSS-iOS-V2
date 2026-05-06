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

public struct WSSFeadHeaderView: View {
    
    let profileImageURL: URL?
    let nickname: String
    let createdDate: String
    let isEdited: Bool
    
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
    
    public var body: some View {
        HStack(spacing: 0) {
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
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Spacer().frame(width: 10)
            
            Text(nickname)
                .applyWSSFont(.body4)
                .foregroundStyle(Color.wssBlack)
            
            Spacer().frame(width: 4)
            
            Circle()
                .frame(width: 2, height: 2)
                .foregroundColor(Color.wssGray200)
                .frame(width: 8, height: 8)
            
            Spacer().frame(width: 4)
            
            Text(createdDate)
                .applyWSSFont(.body5)
                .foregroundStyle(Color.wssGray200)
            
            Spacer().frame(width: 4)
            
            if (isEdited) {
                Text("(수정됨)")
                    .applyWSSFont(.body5)
                    .foregroundStyle(Color.wssGray200)
            }
            
            Spacer()
            
            WSSImage.icThreedots.swiftUIImage
                .frame(width: 32, height: 32, alignment: .trailing)
        }
        .background(Color.wssWhite)
    }
}

#Preview {
    WSSFeadHeaderView(
        profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
        nickname: "구리스",
        createdDate: "2024년 6월 19일",
        isEdited: true
    )
}
