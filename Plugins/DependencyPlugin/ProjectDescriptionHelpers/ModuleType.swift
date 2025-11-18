//
//  ModuleType.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import Foundation

public enum ModuleType {
    public enum Feature: String {
        case home
        case feed
        
        public var name: String {
            switch self {
            case .home: "HomeFeature"
            case .feed: "FeedFeature"
            }
        }
        
        func targetName(type: TargetType) -> String {
            name + type.suffix
        }
    }
    
    public enum Domain: String {
        case recommendation
        
        public var name: String {
            switch self {
            case .recommendation: "RecommendationDomain"
            }
        }
        
        func targetName(type: TargetType) -> String {
            name + type.suffix
        }
    }
    
    public enum Data: String {
        case recommendation
        
        public var name: String {
            switch self {
            case .recommendation: "RecommendationData"
            }
        }
        
        func targetName(type: TargetType) -> String {
            name + type.suffix
        }
    }
    
    public enum Core: String {
        case keychain
        case networking
        case logger
        
        public var name: String {
            switch self {
            case .keychain: "Keychain"
            case .networking: "Networking"
            case .logger: "Logger"
            }
        }
        
        func targetName(type: TargetType) -> String {
            name + type.suffix
        }
    }
    
    public enum UI: String {
        case designSystem
        case wssComponent
        
        public var name: String {
            switch self {
            case .designSystem: "DesignSystem"
            case .wssComponent: "WSSComponent"
            }
        }
        
        func targetName(type: TargetType) -> String {
            name + type.suffix
        }
    }
}
