//
//  FeedFeatureDemoApp.swift
//  FeedFeatureDemo
//
//  Created by Seoyeon Choi on 6/4/26.
//

import SwiftUI

import FeedFeature

@main
struct FeedFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeedFeatureFactory.makeCreateFeedPreviewView()
            }
        }
    }
}
