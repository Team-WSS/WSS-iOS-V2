//
//  ConfigDemoView.swift
//  App
//
//  Created by Seoyeon Choi on 11/3/25.
//

import SwiftUI

import Utilites

public struct ConfigDemoView: View {
    private var values: [(String, String)] {
        return [
            ("BASE_URL", Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.baseURL) as? String ?? "❌ Not Found"),
            ("TEST_TOKEN", Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.testToken) as? String ?? "❌ Not Found"),
            ("BUCKET_URL", Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.bucketURL) as? String ?? "❌ Not Found"),
            ("KAKAO_APP_KEY", Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.kakaoAppKey) as? String ?? "❌ Not Found"),
            ("AMPLITUDE_API_KEY", Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.amplitudeAPIKey) as? String ?? "❌ Not Found")
        ]
    }
    
    public var body: some View {
        NavigationView {
            List(values, id: \.0) { key, value in
                HStack {
                    Text(key)
                        .font(.headline)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Plist Config Test")
        }
    }
}
