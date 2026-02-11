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
        case base
        
        case recommendation
        case feed
        case keyword
        case comment
        case novel
        case novelReview
        case setting
        case notification
        
        public var name: String {
            switch self {
            case .base: "BaseDomain"
            case .recommendation: "RecommendationDomain"
            case .feed: "FeedDomain"
            case .keyword: "KeywordDomain"
            case .comment: "CommentDomain"
            case .novel: "NovelDomain"
            case .novelReview: "NovelReviewDomain"
            case .setting: "SettingDomain"
            case .notification: "NotificationDomain"
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
