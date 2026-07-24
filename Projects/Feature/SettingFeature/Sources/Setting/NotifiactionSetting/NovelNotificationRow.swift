//
//  NovelNotificationRow.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

struct NovelNotificationRow: View {

    var body: some View {
        HStack(spacing: 18) {
            AsyncImage(url:
                        URL(string: "https://i.pinimg.com/736x/f5/09/cf/f509cf911c368b54f01e394dd47e4e23.jpg")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                case .failure(_):
                    WSSImage.imgEmptyCover.swiftUIImage
                        .resizable()
                default :
                    ProgressView()
                }
            }
            .scaledToFill()
            .frame(width: 78, height: 105)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("시어머니, 제가 이긴 게임이에요")
                    .applyWSSFont(.title3)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Text("여기서끊는다고")
                    .applyWSSFont(.body5_2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                
                Text("2001.10.03 등록")
                    .applyWSSFont(.body5)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            
            Spacer()
            
            Button {
                
            } label: {
                WSSImage.icSelectNovelDefault.swiftUIImage
            }
            .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    NovelNotificationRow()
}
