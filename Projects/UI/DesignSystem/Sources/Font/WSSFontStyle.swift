//
//  WSSFontStyle.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import SwiftUI

public enum WSSFontStyle {
    case headline1
    
    case title1
    case title2
    case title3
    
    case body1
    case body2
    case body3
    case body4
    case body4_2
    case body5
    case body5_2
    
    case label1
    case label2
}

public extension WSSFontStyle {
    var fontName: DesignSystemFontConvertible {
        switch self {
        case .headline1:
            return DesignSystemFontFamily.Pretendard.bold
            
        case .title1:
            return DesignSystemFontFamily.Pretendard.bold
        case .title2:
            return DesignSystemFontFamily.Pretendard.semiBold
        case .title3:
            return DesignSystemFontFamily.Pretendard.medium
            
        case .body1:
            return DesignSystemFontFamily.Pretendard.regular
        case .body2:
            return DesignSystemFontFamily.Pretendard.regular
        case .body3:
            return DesignSystemFontFamily.Pretendard.regular
        case .body4:
            return DesignSystemFontFamily.Pretendard.medium
        case .body4_2:
            return DesignSystemFontFamily.Pretendard.regular
        case .body5:
            return DesignSystemFontFamily.Pretendard.regular
        case .body5_2:
            return DesignSystemFontFamily.Pretendard.medium
            
        case .label1:
            return DesignSystemFontFamily.Pretendard.medium
        case .label2:
            return DesignSystemFontFamily.Pretendard.medium
        }
    }
}

extension WSSFontStyle {
    private static let scaleRatio: CGFloat = max(1.adjustedHeight, 1.adjustedWidth)
    
    var defaultFontSize: CGFloat {
        switch self {
        case .headline1: 20
            
        case .title1: 18
        case .title2: 16
        case .title3: 14
            
        case .body1: 17
        case .body2: 15
        case .body3: 14
        case .body4: 13
        case .body4_2: 13
        case .body5: 12
        case .body5_2: 12
            
        case .label1: 13
        case .label2: 10
        }
    }
    
    private var adjustedSize: CGFloat {
        return defaultFontSize * WSSFontStyle.scaleRatio
    }
    
    func uiFontGuide() -> UIFont {
        switch self {
        default: return UIFont(name: self.fontName.name, size: self.adjustedSize)!
        }
    }
}

extension WSSFontStyle {
    var letterSpacing: CGFloat {
        switch self {
        case .headline1: -0.6
            
        case .title1: -0.6
        case .title2: -0.6
        case .title3: -0.6
            
        case .body1: -0.6
        case .body2: -0.6
        case .body3: -0.4
        case .body4: -0.4
        case .body4_2: -0.4
        case .body5: 0
        case .body5_2: 0
            
        case .label1: -0.4
        case .label2: 0
        }
    }
    
    var lineHeight: CGFloat {
        switch self {
        case .headline1: return 1.4
            
        case .title1: return 1.4
        case .title2: return 1.4
        case .title3: return 1.5
            
        case .body1: return 1.4
        case .body2: return 1.5
        case .body3: return 1.5
        case .body4: return 1.45
        case .body4_2: return 1.45
        case .body5: return 1.45
        case .body5_2: return 1.45
            
        case .label1: return 1.45
        case .label2: return 1.0
        }
    }
}
