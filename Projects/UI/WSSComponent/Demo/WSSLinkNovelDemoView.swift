//
//  WSSLinkNovelDemoView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import WSSComponent
import DesignSystem

struct WSSLinkNovelDemoView: View {
    var body: some View {
        VStack {
            LinkNovelView(
                genreType: .lightNovel,
                novelTitle: "스즈미야 하루히의 무료",
                novelRating: 4.3
            )
            
            LinkNovelView(
                genreType: .wuxia,
                novelTitle: "화산귀환",
                novelRating: 4.0
            )
            
            LinkNovelView(
                genreType: .fantasy,
                novelTitle: "마법학교 마법사로 살아가는 법",
                novelRating: 4.3
            )
            
            LinkNovelView(
                genreType: .romance,
                novelTitle: "사내 연애에서 살아남기",
                novelRating: 4.3
            )
            
            LinkNovelView(
                genreType: .bl,
                novelTitle: "당신과 함께한 30일",
                novelRating: 5.0
            )
            
            LinkNovelView(
                genreType: .romanceFantasy,
                novelTitle: "공주는 아무나 하나요",
                novelRating: 4.2
            )
            
            LinkNovelView(
                genreType: .modernFantasy,
                novelTitle: "괴담에 떨어져도 출근을 해야 하는구나",
                novelRating: 4.1
            )
            
            LinkNovelView(
                genreType: .drama,
                novelTitle: "죽음을 삽니다",
                novelRating: 4.5
            )
            
            LinkNovelView(
                genreType: .mystery,
                novelTitle: "셜록 홈즈 1 - 주홍색 연구",
                novelRating: 1.2
            )
        }
    }
}
