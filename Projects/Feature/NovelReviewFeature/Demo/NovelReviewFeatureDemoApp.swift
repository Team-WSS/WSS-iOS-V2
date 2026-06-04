//
//  NovelReviewFeatureDemoApp.swift
//  NovelReviewFeatureDemo
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewFeature

@main
struct NovelReviewFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                NovelReviewFactory.makeView(novelID: NovelID(1))
            }
        }
    }
}
