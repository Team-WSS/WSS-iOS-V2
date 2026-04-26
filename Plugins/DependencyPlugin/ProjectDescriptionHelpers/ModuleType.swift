//
//  ModuleType.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import Foundation

public protocol ModuleSpec: RawRepresentable where RawValue == String {
    var moduleSuffix: String { get }
}

public extension ModuleSpec {
    var name: String {
        rawValue.pascalCased + moduleSuffix
    }
}

public enum FeatureModule: String, ModuleSpec {
    public var moduleSuffix: String { "Feature" }
    
    case home
    case feed
}

public enum DomainModule: String, ModuleSpec {
    public var moduleSuffix: String { "Domain" }
    
    case base
    case auth
    case recommendation
    case feed
    case keyword
    case comment
    case novel
    case novelReview
    case setting
    case notification
    case profile
    case social
}

public enum DataModule: String, ModuleSpec {
    public var moduleSuffix: String { "Data" }
    
    case base
    case recommendation
    case novelReview
    case notification
    case keyword
    case comment
}

public enum CoreModule: String, ModuleSpec {
    public var moduleSuffix: String { "" }
    
    case keychain
    case networking
    case logger
}

public enum UIModule: String, ModuleSpec {
    public var moduleSuffix: String { "" }
    
    case designSystem
    case wssComponent
    
    public var name: String {
        switch self {
        case .wssComponent: return "WSSComponent"
        default: return rawValue.pascalCased + moduleSuffix
        }
    }
}

public enum ModuleType {
    case feature(FeatureModule)
    case domain(DomainModule)
    case data(DataModule)
    case core(CoreModule)
    case ui(UIModule)

    public var name: String {
        switch self {
        case let .feature(module):  module.name
        case let .domain(module):   module.name
        case let .data(module):     module.name
        case let .core(module):     module.name
        case let .ui(module):       module.name
        }
    }

    public var directoryName: String {
        switch self {
        case .feature:  "Feature"
        case .domain:   "Domain"
        case .data:     "Data"
        case .core:     "Core"
        case .ui:       "UI"
        }
    }

    public func targetName(type: TargetType) -> String {
        name + type.suffix
    }
}

private extension String {
    var pascalCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let spaced = replacingOccurrences(
            of: pattern,
            with: "$1 $2",
            options: .regularExpression
        )

        return spaced
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }
}
