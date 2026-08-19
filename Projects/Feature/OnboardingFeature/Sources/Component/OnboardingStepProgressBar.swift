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
/// `currentStep`은 1부터 시작.
///
/// **컨테이너(`OnboardingStepFlowView`)가 이 뷰를 단계 전환 내내 같은 인스턴스로 유지**하는 게 전제다 —
/// 그래야 `currentStep` 값 변화에 `.animation(value:)`가 실제로 반응해 폭이 자연스럽게 늘어난다.
/// (예전에는 각 단계가 별도 화면(별도 View 인스턴스)이라 상태를 공유 못 해 `onAppear` 시점에
/// `currentStep - 1`에서 `currentStep`으로 스스로 되감아 애니메이션하는 우회를 썼었다 — 세그먼트별
/// `.fill` 색 크로스페이드라 "채워지는" 느낌도 약했다. 컨테이너로 통합되며 더 이상 필요 없어져 제거.)
struct OnboardingStepProgressBar: View {

    let currentStep: Int
    let totalSteps: Int

    init(currentStep: Int, totalSteps: Int = 3) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.wssGray70

                Color.wssPrimary100
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps))
                    .animation(.easeInOut(duration: 0.35), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingStepProgressBar(currentStep: 1)
        OnboardingStepProgressBar(currentStep: 2)
        OnboardingStepProgressBar(currentStep: 3)
    }
}
