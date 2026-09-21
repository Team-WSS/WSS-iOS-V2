//
//  WSSAlertButton.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WSSAlertButton {
    let title: String
    let role: WSSButtonRole
}

public enum WSSButtonRole {
    case confirm
    case cancel
    case dismiss
    case destructive
    
    var backgroundColor: Color {
        switch self {
        case .confirm:          WSSColor.wssPrimary100.swiftUIColor
        case .destructive:      WSSColor.wssSecondary100.swiftUIColor
        case .cancel:           WSSColor.wssGray50.swiftUIColor
        case .dismiss:          WSSColor.wssGray70.swiftUIColor
        }
    }

    var textColor: Color {
        switch self {
        case .confirm, .destructive:
            WSSColor.wssWhite.swiftUIColor
        case .cancel, .dismiss:
            WSSColor.wssGray300.swiftUIColor
        }
    }
}
