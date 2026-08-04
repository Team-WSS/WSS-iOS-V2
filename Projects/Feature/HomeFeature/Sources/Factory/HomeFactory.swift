//
//  HomeFactory.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

/// 홈 화면의 유일한 public 진입점. View/ViewModel은 internal로 감춘다.
public enum HomeFactory {

    // 모듈 골격 placeholder — UseCase·콜백 주입은 골격 단계에서 채운다.
    @MainActor
    public static func makeView() -> some View {
        HomeView()
    }
}
