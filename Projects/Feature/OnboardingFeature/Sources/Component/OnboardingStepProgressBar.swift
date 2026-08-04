//
//  OnboardingStepProgressBar.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 온보딩 나머지 3단계(닉네임→성별/출생년도→장르선택) 공통 진행바. Figma `progressbar` 컴포넌트를 그대로 반영.
/// `currentStep`은 1부터 시작 — 앞의 `currentStep`개 세그먼트가 `wssPrimary100`, 나머지는 `wssGray70`.
struct OnboardingStepProgressBar: View {

    let currentStep: Int
    let totalSteps: Int

    init(currentStep: Int, totalSteps: Int = 3) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Rectangle()
                    .fill(index < currentStep ? Color.wssPrimary100 : Color.wssGray70)
                    .frame(height: 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingStepProgressBar(currentStep: 1)
        OnboardingStepProgressBar(currentStep: 2)
        OnboardingStepProgressBar(currentStep: 3)
    }
}
