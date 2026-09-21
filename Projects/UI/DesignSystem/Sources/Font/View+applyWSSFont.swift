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
    public func applyWSSFont(_ style: WSSFontStyle) -> some View {
        modifier(
            WSSFontViewModifier(
                uiFont: style.uiFontGuide(),
                lineHeight: style.fontSize * style.lineHeight,
                letterSpacing: style.letterSpacing
            )
        )
    }

    public func applyWSSFont(
        _ style: WSSFontStyle,
        color: Color,
        alignment: TextAlignment = .center
    ) -> some View {
        self
            .applyWSSFont(style)
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
    }
}
