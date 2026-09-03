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
            static let kakaoCollectionShareTemplateID1 = "KAKAO_COLLECTION_SHARE_TEMPLATE_ID_1"
            static let kakaoCollectionShareTemplateID2 = "KAKAO_COLLECTION_SHARE_TEMPLATE_ID_2"
            static let kakaoCollectionShareTemplateID3 = "KAKAO_COLLECTION_SHARE_TEMPLATE_ID_3"
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
    public static let kakaoAppKey: String = Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.kakaoAppKey) as? String ?? ""
    // 컬렉션 공유 카드의 Kakao Developers 콘솔 커스텀 템플릿 ID 3종 — Kakao 커스텀 템플릿은 이미지 슬롯
    // 개수가 고정이라(가변 개수 불가, 2026-09-01 실측) 작품 1/2/3개 이상 각각 별도 템플릿을 만들어야 한다.
    // 팀원마다 다른 콘솔에 만들어질 수 있는 값이라 git에 커밋되는 Swift 소스가 아니라 gitignore된
    // `Config/*.xcconfig`에서 읽는다(`CollectionFeature/CLAUDE.md` 공유 항목). 셋 중 하나라도 미설정(0)이면
    // 그 작품 수에 한해 호출부가 기본 카드(표지 1장)로 폴백한다 — 나머지 두 개수는 영향받지 않는다.
    public static let kakaoCollectionShareTemplateID1: Int64 = Int64(
        Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.kakaoCollectionShareTemplateID1) as? String ?? ""
    ) ?? 0
    public static let kakaoCollectionShareTemplateID2: Int64 = Int64(
        Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.kakaoCollectionShareTemplateID2) as? String ?? ""
    ) ?? 0
    public static let kakaoCollectionShareTemplateID3: Int64 = Int64(
        Bundle.main.object(forInfoDictionaryKey: Config.Keys.Plist.kakaoCollectionShareTemplateID3) as? String ?? ""
    ) ?? 0
}
