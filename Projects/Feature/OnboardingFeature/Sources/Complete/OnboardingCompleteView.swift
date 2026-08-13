//
//  OnboardingCompleteView.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/14/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import Lottie

import DesignSystem
import WSSComponent

/// 온보딩 마지막 화면(#178) — 프로필 등록 성공 직후 뜨는 "계약 완료" 안내. `OnboardingStepFlowView`가
/// `GenreSelectionView`의 등록 성공 신호를 받으면 컨테이너 콘텐츠 전체를 이 화면으로 교체한다(진행바·
/// 뒤로가기 없음 — Figma에도 그 둘이 없다). UseCase도 VM도 없는 순수 표시 화면이라 닉네임 문자열과
/// 확정 콜백만 값으로 받는다(`NormalSearchResultView`와 같은 "props-only" 패턴).
struct OnboardingCompleteView: View {

    let nickname: String
    /// "웹소소 시작하기" 탭 시 발화 — 실제 Home 진입은 호출자(App) 책임.
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 94)

            titleSection

            Spacer().frame(height: 35)

            LottieView(animation: WSSLottie.onboardingComplete)
                .playing(loopMode: .loop)
                .frame(width: 300, height: 300)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wssWhite)
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }
}

// MARK: - Sections

private extension OnboardingCompleteView {
    var titleSection: some View {
        VStack(spacing: 10) {
            Text("웹소소와 계약 완료!")
                .applyWSSFont(.headline1, color: .wssBlack)

            Text("\(nickname)님, 만나서 반가워요!")
                .applyWSSFont(.body2, color: .wssGray300)
        }
    }

    var ctaButton: some View {
        WSSCTAButton(title: "웹소소 시작하기", action: onStart)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompleteView(nickname: "구리구리스", onStart: { print("웹소소 시작하기") })
}
