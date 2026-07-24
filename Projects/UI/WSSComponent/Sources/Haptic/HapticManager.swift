//
//  HapticManager.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UIKit

/// 앱 전역에서 쓰는 햅틱 피드백 트리거. 호출부가 상황에 맞는 스타일을 직접 골라 쓴다.
public enum HapticManager {
    public enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid

        var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:    .light
            case .medium:   .medium
            case .heavy:    .heavy
            case .soft:     .soft
            case .rigid:    .rigid
            }
        }
    }

    /// 정렬·필터 전환처럼 가벼운 상태 변경 시.
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// 버튼 탭 등 물리적 충격감이 필요할 때.
    public static func impact(_ style: ImpactStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 성공/실패/경고 등 결과를 알릴 때.
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
