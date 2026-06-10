//
//  FeedFeatureDemoApp.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import DesignSystem
import FeedFeature

@main
struct FeedFeatureDemoApp: App {
    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }
    var body: some Scene {
        WindowGroup {
            FeedFeatureFactory.makeCreateFeedPreviewView()
        }
    }
}
