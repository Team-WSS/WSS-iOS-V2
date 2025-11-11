//
//  ModuleType.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import Foundation

public enum ModuleType {
    case feature(Feature)
    case domain(Domain)
    case data(Data)
    case core(Core)
    case ui(UI)
}

public extension ModuleType {
    enum Feature: String {
        case HomeFeature
        case FeedFeature
        
        public var name: String { self.rawValue }

        func targetName(type: TargetType) -> String {
            "\(self.rawValue)\(type.rawValue)"
        }
    }
}

public extension ModuleType {
    enum Domain: String {
        case RecommendationDomain
        
        public var name: String { self.rawValue }

        func targetName(type: TargetType) -> String {
            "\(self.rawValue)\(type.rawValue)"
        }
    }
}

public extension ModuleType {
    enum Data: String {
        case RecommendationData
        
        public var name: String { self.rawValue }

        func targetName(type: TargetType) -> String {
            "\(self.rawValue)\(type.rawValue)"
        }
    }
}

public extension ModuleType {
    enum Core: String {
        case Keychain
        case Networking
        case Logger
        
        public var name: String { self.rawValue }

        func targetName(type: TargetType) -> String {
            "\(self.rawValue)\(type.rawValue)"
        }
    }
}

public extension ModuleType {
    enum UI: String {
        case DesignSystem
        case WSSComponent
        
        public var name: String { self.rawValue }
        
        func targetName(type: TargetType) -> String {
            "\(self.rawValue)\(type.rawValue)"
        }
    }
}

public enum TargetType: String {
    case sources = ""
    case demo = "Demo"
    case tests = "Tests"
}
