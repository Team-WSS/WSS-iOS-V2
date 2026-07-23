//
//  FeedFeatureDemoHome.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import BaseData

/// 지금까지 만든 화면들을 한곳에서 골라 들어갈 수 있는 데모 허브.
struct FeedFeatureDemoHome: View {

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("피드 작성") {
                    CreateFeedDemoScene()
                }
                NavigationLink("피드 상세") {
                    FeedDetailDemoScene()
                }
            }
            .navigationTitle("FeedFeature Demo")
        }
        // 버킷 이미지 스케일 주입 — 실제 앱에선 루트 뷰가 같은 방식으로 1회 설정한다.
        .onAppear { ImageURLResolver.displayScale = Int(displayScale.rounded()) }
    }
}
