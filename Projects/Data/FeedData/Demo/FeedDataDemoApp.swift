//
//  FeedDataDemoApp.swift
//  FeedDataDemo
//
//  Created by WonsunLee on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import FeedData
import BaseData

@main
struct FeedDataDemoApp: App {

    init() {
        let storage = UserDefaultsStorage()
        storage.set(.userID, 10033)
    }

    var body: some Scene {
        WindowGroup {
            FeedDataDemoView()
        }
    }
}
