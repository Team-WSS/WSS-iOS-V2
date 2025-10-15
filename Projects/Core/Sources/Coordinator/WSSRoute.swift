//
//  WSSRoute.swift
//  Core
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

enum WSSRoute: Hashable {
    case home
    case search
}

enum WSSSheet: Identifiable {
    case none
    
    var id: String {
        switch self {
        case .none:
            return "none"
        }
    }
}

enum WSSFullScreenCover: Identifiable {
    case none
    
    var id: String {
        switch self {
        case .none:
            return "none"
        }
    }
}
