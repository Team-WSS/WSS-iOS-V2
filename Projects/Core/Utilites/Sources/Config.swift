//
//  Config.swift
//  Utilites
//
//  Created by Seoyeon Choi on 11/3/25.
//

import Foundation

public enum Config {
    public enum Keys {
        public enum Plist {
            public static let baseURL = "BASE_URL"
            public static let testToken = "TEST_TOKEN"
            public static let bucketURL = "BUCKET_URL"
            public static let kakaoAppKey = "KAKAO_APP_KEY"
            public static let amplitudeAPIKey = "AMPLITUDE_API_KEY"
        }
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist cannot found.")
        }
        return dict
    }()
}
