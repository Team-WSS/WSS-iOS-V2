//
//  TargetType.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/18/25.
//

import Foundation

public enum TargetType {
    case sources
    case demo
    case testing
    case tests

    var suffix: String {
        switch self {
        case .sources: return ""
        case .demo: return "Demo"
        case .testing: return "Testing"
        case .tests: return "Tests"
        case .testing: return "Testing"
        }
    }
}
