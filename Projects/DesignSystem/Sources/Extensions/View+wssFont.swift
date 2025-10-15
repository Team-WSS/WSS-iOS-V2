//
//  View+wssFont.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

enum PretendardWeight: String {
    case bold = "Pretendard-Bold"
    case semibold = "Pretendard-SemiBold"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"
}

public enum wssFontType {
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
    
    var fontName: PretendardWeight {
        switch self {
        case .headline1, .title1: return .bold
        case .title2: return .semibold
        case .title3, .body4, .body5_2, .label1, .label2: return .medium
        case .body1, .body2, .body3, .body4_2, .body5: return .regular
        }
    }
    
    var fontSize: CGFloat {
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
    
    var lineHeight: CGFloat {
        switch self {
        case .headline1: 140
        case .title1: 140
        case .title2: 140
        case .title3: 100
        case .body1: 140
        case .body2: 150
        case .body3: 150
        case .body4: 145
        case .body4_2: 145
        case .body5: 145
        case .body5_2: 145
        case .label1: 145
        case .label2: 100
        }
    }
    
    var letterSpacing: CGFloat {
        switch self {
        case .headline1: -1.2
        case .title1, .title2, .title3, .body1, .body2: -0.6
        case .body3, .body4, .body4_2, .label1: -0.4
        case .body5, .body5_2, .label2: 0
        }
    }
}

extension View {
    public func wssFont(_ type: wssFontType) -> some View {
        let font = UIFont(name: type.fontName.rawValue, size: type.fontSize) ?? UIFont.systemFont(ofSize: type.fontSize)
        let calculatedLineHeight = type.fontSize * (type.lineHeight / 100)
        let kerning = (type.letterSpacing / 100) * type.fontSize
        let lineSpacing = max(0, calculatedLineHeight - font.lineHeight)
        let verticalPadding = max(0, lineSpacing / 2)

        return self
            .font(Font(font))
            .kerning(kerning)
            .lineSpacing(lineSpacing)
            .padding(.vertical, verticalPadding)
    }
}
