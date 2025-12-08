//
//  WSSFontViewModifier.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 12/8/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import SwiftUI
import UIKit

struct WSSFontViewModifier: ViewModifier {
    let uiFont: UIFont
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
    
    func body(content: Content) -> some View {
        return content
            .font(Font(uiFont))
            .lineSpacing(lineHeight - uiFont.lineHeight)
            .kerning(letterSpacing)
            .padding(.vertical, (lineHeight - uiFont.lineHeight) / 2)
    }
}
