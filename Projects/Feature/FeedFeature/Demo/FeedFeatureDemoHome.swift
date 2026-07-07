//
//  FeedFeatureDemoHome.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

/// 지금까지 만든 화면들을 한곳에서 골라 들어갈 수 있는 데모 허브.
struct FeedFeatureDemoHome: View {

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
    }
}
