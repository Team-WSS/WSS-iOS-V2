//
//  NetworkingConfig.swift
//  Networking
//
//  Created by Seoyeon Choi on 11/12/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

enum Config {
    enum Keys {
        enum Plist {
            static let baseURL = "BASE_URL"
            static let testToken = "TEST_API_KEY"
            static let bucketURL = "BUCKET_URL"
            static let kakaoAppKey = "KAKAO_APP_KEY"
            static let appStoreID = "APPSTORE_ID"
            static let amplitudeAPIKey = "AMPLITUDE_API_KEY"
        }
    }
}

public enum NetworkingConfig {
    // 앱 시작 시 plist에서 한 번 읽어 고정되는 읽기 전용 설정값 → `let`(재할당 없음, Sendable-safe).
    // (`var`였으나 어디서도 재할당하지 않아 concurrency-safe하지 않았다 — Swift 6에서 error.)
    public static let baseURL: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.baseURL) as? String ?? ""
    public static let testApiKey: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.testToken) as? String ?? ""
    public static let bucketURL: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.bucketURL) as? String ?? ""
}
