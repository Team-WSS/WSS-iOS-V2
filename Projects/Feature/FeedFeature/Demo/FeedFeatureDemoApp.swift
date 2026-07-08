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
            SosoFeedDemoScene()
            //CreateFeedDemoScene()
        }
    }
}
