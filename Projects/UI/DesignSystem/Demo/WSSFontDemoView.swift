//
//  WSSFontDemoView.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

struct WSSFontDemoView: View {
    var body: some View {
        VStack {
            Text("Headline1")
                .applyWSSFont(.headline1)
                .background(DesignSystemAsset.PrimaryColor.wssPrimary100.swiftUIColor)
            
            Text("Title1")
                .applyWSSFont(.title1)
            
            Text("Title2")
                .applyWSSFont(.title2)
            
            Text("Title3")
                .applyWSSFont(.title3)
            
            Text("Body1")
                .applyWSSFont(.body1)
            
            Text("Body2")
                .applyWSSFont(.body2)
            
            Text("Body3")
                .applyWSSFont(.body3)
            
            Text("Body4")
                .applyWSSFont(.body4)
            
            Text("Body4_2")
                .applyWSSFont(.body4_2)
            
            Text("Body5")
                .applyWSSFont(.body5)
            
            Text("Body5_2")
                .applyWSSFont(.body5)
            
            Text("Label1")
                .applyWSSFont(.label1)
            
            Text("Label2")
                .applyWSSFont(.label2)
        }
        .padding(40)
    }
}

#Preview {
    WSSFontDemoView()
}
