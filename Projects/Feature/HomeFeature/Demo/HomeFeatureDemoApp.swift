//
//  HomeFeatureDemoApp.swift
//  HomeFeatureDemo
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import HomeFeature
import DesignSystem

@main
struct HomeFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        // 프리뷰는 이 Demo 앱을 호스트로 띄우므로 여기서 등록하면 프리뷰도 함께 해결된다.
        DesignSystemFontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            // 모듈 골격 placeholder — Mock/실서버 토글·UseCase 조립은 골격 단계에서 채운다.
            NavigationStack {
                HomeFactory.makeView()
            }
        }
    }
}
