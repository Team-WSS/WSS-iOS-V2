//
//  WSSFontDemoView.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

struct WSSFontDemoView: View {
    var body: some View {
        VStack {
            Text("제목입니다 제목이라구요 제목이야 이게 제목이라고")
                .applyWSSFont(.headline1)
                .border(Color.wssPrimary20)
           
            Text("마법학교 마법사로 살아가는 법마법학교 마법사로 살아가는 법마법학교 마법사로 살아가는 법")
                .applyWSSFont(.title3)
                .border(Color.wssBlack)
                .foregroundStyle(Color.modernLink)
            
            Text("대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고설정을 짠게 느껴져서 좋아요. 요즘 하도 라이트하고 가짜 마법물이 많아서 ㅠ 찐 성장+마법물!!글고 일단 작가님 필력이 무난하게 잘뽑으시고 연재도 빠르")
                .applyWSSFont(.body2)
                .border(Color.wssPrimary100)
            
            Image(uiImage: WSSImage.imgLogoType.image)
            Image(uiImage: WSSImage.icAnnouncement.image)
            Image(uiImage: WSSImage.icTextHot.image)
            WSSImage.icAnnouncement.swiftUIImage
            WSSImage.imgLogoType.swiftUIImage
        }
        .padding(40)
    }
}

#Preview {
    WSSFontDemoView()
}
