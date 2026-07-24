//
//  KeywordFeatureDemoApp.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import BaseDomain
import BaseData
import Logger
import Networking

import KeywordFeature

@main
struct KeywordFeatureDemoApp: App {

    init() {
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// Demo가 App(DI) 역할을 대행해 실서버 Repository로 UseCase를 조립한다.
private struct DemoRootView: View {
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        KeywordFeatureFactory.makeSearchKeywordView(
            loadTotalKeywordsUseCase: DefaultFetchTotalKeywordsUseCase(
                keywordRepository: KeywordDataFactory.makeRepository(
                    client: NetworkingClient(
                        logger: DefaultNetworkLogger(base: consoleLogger),
                        tokenStore: DemoSessionTokenStore()
                    ),
                    logger: DataLogger(moduleName: "KeywordFeatureDemo", underlying: consoleLogger)
                )
            ),
            logger: consoleLogger
        )
    }
}

