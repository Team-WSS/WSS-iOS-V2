//
//  RecommendationDataDemo.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/31/25.
//

import SwiftUI

struct RecommendationDataDemo: View {
    var body: some View {
        Text("dfdf")
            .task {
                if let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String {
                    print("🌍 BASE_URL:", baseURL)
                } else {
                    print("⚠️ BASE_URL을 Info.plist에서 찾을 수 없음")
                }
                
                if let BUCKET_URL = Bundle.main.object(forInfoDictionaryKey: "BUCKET_URL") as? String {
                    print("🌍 BUCKET_URL:", BUCKET_URL)
                } else {
                    print("⚠️ BUCKET_URL을 Info.plist에서 찾을 수 없음")
                }
                
                if let AMPLITUDE_API_KEY = Bundle.main.object(forInfoDictionaryKey: "AMPLITUDE_API_KEY") as? String {
                    print("🌍 AMPLITUDE_API_KEY:", AMPLITUDE_API_KEY)
                } else {
                    print("⚠️ AMPLITUDE_API_KEY을 Info.plist에서 찾을 수 없음")
                }
            }
    }
}
