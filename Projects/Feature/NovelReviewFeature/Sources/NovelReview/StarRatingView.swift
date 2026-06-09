//
//  StarRatingView.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

/// 별점 입력 — 탭/드래그(슬라이드)로 0.5 단위 점수를 부여한다.
/// 별 에셋(`icLargeStar*`)은 살몬색이 박혀 있어 틴팅 없이 채움/반쪽/빈 이미지를 교체해 표현한다.
struct StarRatingView: View {

    let rating: Double
    let onChange: (Double) -> Void

    private let starCount = 5
    private let starSize: CGFloat = 30
    private let spacing: CGFloat = 10

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<starCount, id: \.self) { index in
                image(for: index)
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
            }
        }
        .contentShape(Rectangle())
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        // minimumDistance 0 → 단순 탭도 onChanged로 잡혀 탭/슬라이드를 한 제스처로 처리.
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                update(at: value.location.x, totalWidth: geo.size.width)
                            }
                    )
            }
        }
    }

    /// index번째 별을 현재 점수에 맞춰 채움/반쪽/빈 상태로 그린다.
    private func image(for index: Int) -> Image {
        let starValue = Double(index + 1)
        if rating >= starValue {
            return WSSImage.icLargeStarFilled.swiftUIImage
        } else if rating + 0.5 >= starValue {
            return WSSImage.icLargeStarHalf.swiftUIImage
        } else {
            return WSSImage.icLargeStarEmpty.swiftUIImage
        }
    }

    /// 터치 x좌표 → 0.5 단위 점수. 별 경계를 넘기면 그 별을 채우도록 올림(.up) 처리.
    private func update(at x: CGFloat, totalWidth: CGFloat) {
        guard totalWidth > 0 else { return }
        let raw = Double(x / totalWidth) * Double(starCount)   // 0...5
        let stepped = (raw * 2).rounded(.up) / 2
        // 0.5 단위
        let clamped = min(max(stepped, 0), Double(starCount))
        onChange(clamped)
    }
}
