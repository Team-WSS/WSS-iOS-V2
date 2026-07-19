//
//  TextFieldMaxLengthModifier.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

public struct MaxLengthModifier: ViewModifier {
    @Binding var text: String
    let maxLength: Int

    public func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > maxLength {
                    text = oldValue
                }
            }
    }
}
