//
//  LibraryRatingSlider.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

// 별점 범위 슬라이더 — 0.0~5.0을 0.5 단위로 스냅하는 양쪽 핸들 슬라이더.
// 시스템 Slider는 단일 값만 지원해 화면 전용으로 직접 그린다.
struct LibraryRatingSlider: View {

    let min: Float
    let max: Float
    /// "별점 없음" 토글이 켜지면 편집 잠금 + 회색 표시.
    let isDisabled: Bool
    let onChange: (Float, Float) -> Void

    private static let bounds: ClosedRange<Float> = 0.0...5.0
    private static let step: Float = 0.5
    private static let handleSize: CGFloat = 16
    private static let tickCount = 11

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                track(width: width)
                activeSegment(width: width)
                ticks(width: width)
                handle(at: min, width: width)
                handle(at: max, width: width)
            }
            .frame(height: Self.handleSize)
            // 트랙(4px)이 얇아 그대로는 잡기 어렵다 — 슬라이더 전체 높이를 히트 영역으로.
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
        }
        .frame(height: Self.handleSize)
    }

    // MARK: - Parts

    private func track(width: CGFloat) -> some View {
        Capsule()
            .fill(isDisabled ? Color.wssGray50 : Color.wssPrimary50)
            .frame(height: 4)
    }

    private func activeSegment(width: CGFloat) -> some View {
        let minX = position(of: min, width: width)
        let maxX = position(of: max, width: width)
        return Capsule()
            .fill(isDisabled ? Color.wssGray100 : Color.wssPrimary100)
            .frame(width: Swift.max(maxX - minX, 0), height: 6)
            .offset(x: minX)
    }

    private func ticks(width: CGFloat) -> some View {
        ForEach(0..<Self.tickCount, id: \.self) { index in
            let value = Self.bounds.lowerBound + Float(index) * Self.step
            RoundedRectangle(cornerRadius: 1)
                .fill(isDisabled ? Color.wssGray100 : Color.wssPrimary100)
                .frame(width: 1, height: 2)
                .offset(x: position(of: value, width: width))
        }
    }

    private func handle(at value: Float, width: CGFloat) -> some View {
        Circle()
            .fill(Color.wssWhite)
            .overlay(
                Circle().stroke(isDisabled ? Color.wssGray100 : Color.wssPrimary100, lineWidth: 1)
            )
            .shadow(color: .wssBlack.opacity(0.12), radius: 2, y: 1)
            .frame(width: Self.handleSize, height: Self.handleSize)
            .offset(x: position(of: value, width: width) - Self.handleSize / 2)
    }

    // MARK: - Geometry

    private func position(of value: Float, width: CGFloat) -> CGFloat {
        let fraction = CGFloat((value - Self.bounds.lowerBound) / (Self.bounds.upperBound - Self.bounds.lowerBound))
        return fraction * width
    }

    private func value(atX x: CGFloat, width: CGFloat) -> Float {
        let fraction = Float(Swift.min(Swift.max(x / Swift.max(width, 1), 0), 1))
        let raw = Self.bounds.lowerBound + fraction * (Self.bounds.upperBound - Self.bounds.lowerBound)
        let snapped = (raw / Self.step).rounded() * Self.step
        return Swift.min(Swift.max(snapped, Self.bounds.lowerBound), Self.bounds.upperBound)
    }

    /// 탭/드래그 지점에서 가까운 핸들을 움직인다. 두 핸들이 교차하지 않게 상대 핸들 값으로 클램프.
    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard !isDisabled else { return }
                let tapped = value(atX: gesture.location.x, width: width)
                let distanceToMin = abs(tapped - min)
                let distanceToMax = abs(tapped - max)
                if distanceToMin < distanceToMax || (distanceToMin == distanceToMax && tapped < min) {
                    onChange(Swift.min(tapped, max), max)
                } else {
                    onChange(min, Swift.max(tapped, min))
                }
            }
    }
}
