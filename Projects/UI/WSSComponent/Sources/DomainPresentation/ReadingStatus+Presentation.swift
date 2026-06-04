//
//  ReadingStatus+Presentation.swift
//  WSSComponent
//
//  Created by YunhakLee on 5/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SwiftUI
import DesignSystem

public extension ReadingStatus {
    var statusName: String {
        switch self {
        case .watching: "보는 중"
        case .watched:  "봤어요"
        case .quit:     "하차"
        }
    }
    
    var fillImage: Image {
        switch self {
        case .watching: WSSImage.icWatchingFill.swiftUIImage
        case .watched:  WSSImage.icWatchedFill.swiftUIImage
        case .quit:     WSSImage.icQuitFill.swiftUIImage
        }
    }
    
    var strokeImage: Image {
        switch self {
        case .watching: WSSImage.icWatchingStroke.swiftUIImage
        case .watched:  WSSImage.icWatchedStroke.swiftUIImage
        case .quit:     WSSImage.icQuitStroke.swiftUIImage
        }
    }
    
    var dateText: String {
        switch self {
        case .watching: "시작 날짜"
        case .watched:  "읽은 날짜"
        case .quit:     "종료 날짜"
        }
    }
    
    var graphSectionTitle: String {
        switch self {
        case .watching: "봤어요"
        case .watched:  "같이 보고 있어요"
        case .quit:     "하차했어요"
        }
    }
    
    var tagBackgroundColor: Color {
        switch self {
        case .watching: WSSColor.wssPrimary100.swiftUIColor
        case .watched:  WSSColor.wssBlack.swiftUIColor
        case .quit:     WSSColor.wssGray200.swiftUIColor
        }
    }
}
