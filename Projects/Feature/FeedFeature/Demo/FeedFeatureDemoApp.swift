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
        BucketImageURL.configure()

        let storage = UserDefaultsStorage()
        storage.set(.userID, 10035)
    }

    var body: some Scene {
        WindowGroup {
            FeedDetailDemoScene()
        }
    }
}
