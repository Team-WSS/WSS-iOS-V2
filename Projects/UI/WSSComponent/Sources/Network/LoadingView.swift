//
//  LoadingView.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import Lottie
import DesignSystem

public struct LoadingView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            LottieView(animation: WSSLottie.loading)
                .playing(loopMode: .loop)
                .frame(width: 50, height: 50)

            VStack(spacing: 4) {
                Text("로딩 중")
                    .applyWSSFont(.title2, color: .wssPrimary100)

                Text("잠시만 기다려주세요")
                    .applyWSSFont(.body2, color: .wssGray200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wssWhite.ignoresSafeArea())
    }
}

#Preview {
    LoadingView()
}
