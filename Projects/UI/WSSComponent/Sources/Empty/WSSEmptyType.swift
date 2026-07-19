//
//  WSSEmptyType.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum WSSEmptyType {
    case novel
    case keyword
    case novelNotification
    
    var description: String {
        switch self {
        case .novel:    "해당 검색어를 가진 작품은\n아직 등록되지 않았어요.."
        case .keyword:  "해당 키워드는\n아직 등록되지 않았어요.."
        case .novelNotification: "알림 등록한 작품이 없어요"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .novel: "작품 문의하러 가기"
        case .keyword: "키워드 문의하러 가기"
        case .novelNotification: "작품 둘러보기"
        }
    }
}
