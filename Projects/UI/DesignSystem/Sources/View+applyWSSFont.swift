//
//  View+applyWSSFont.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import UIKit
import SwiftUI

extension View {
    /// 뷰에 applyWSSFont 메소드를 활용하여 폰트를 지정합니다.
    public func applyWSSFont(_ style: WSSFontStyle) -> some View {
        let swiftUIFont = style.fontName.swiftUIFont(size: style.fontSize)
        
        let calculatedLineHeight = style.fontSize * (style.lineHeight / 100)
        let kerning = (style.letterSpacing / 100) * style.fontSize
        let lineSpacing = max(0, calculatedLineHeight - style.lineHeight)
        let verticalPadding = max(0, lineSpacing / 2)
        
        return self
            .font(swiftUIFont)
            .kerning(kerning)
            .lineSpacing(lineSpacing)
            .padding(.vertical, verticalPadding)
    }
}
