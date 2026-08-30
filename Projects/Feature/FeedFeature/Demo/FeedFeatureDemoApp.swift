//
//  FeedFeatureDemoApp.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import DesignSystem
import BaseData

@main
struct FeedFeatureDemoApp: App {

    init() {
        DesignSystemFontFamily.registerAllCustomFonts()

        let storage = UserDefaultsStorage()
        storage.set(.userID, 10045)
    }

    var body: some Scene {
        WindowGroup {
            // 띄울 데모를 바꾸려면 아래 한 줄만 교체:
            //SosoFeedDemoScene()
            //FeedDetailMockDemoScene()   // 오프라인(mock) 피드 상세 — dev 서버 없이 조용한 실패/전송 게이트 확인
            CreateFeedDemoScene()
        }
    }
}
