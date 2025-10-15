//
//  WSSRoute.swift
//  Core
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

public enum WSSRoute: Hashable {
    case home
    case search
}

public enum WSSSheet: Identifiable {
    case none
    
    public var id: String {
        switch self {
        case .none:
            return "none"
        }
    }
}

public enum WSSFullScreenCover: Identifiable {
    case none
    
    public var id: String {
        switch self {
        case .none:
            return "none"
        }
    }
}
