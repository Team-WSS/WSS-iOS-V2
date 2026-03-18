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
            static let testToken = "TEST_TOKEN"
            static let bucketURL = "BUCKET_URL"
            static let kakaoAppKey = "KAKAO_APP_KEY"
            static let appStoreID = "APPSTORE_ID"
            static let amplitudeAPIKey = "AMPLITUDE_API_KEY"
        }
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist cannot found.")
        }
        return dict
    }()
}

public enum NetworkingConfig {
    public static var baseURL: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.baseURL) as? String ?? ""
    public static var testApiKey: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.testToken) as? String ?? ""
}
