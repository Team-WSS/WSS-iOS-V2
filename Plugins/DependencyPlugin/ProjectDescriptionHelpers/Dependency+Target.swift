//
//  Dependency+Target.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension TargetDependency {
    struct Feature {}
    struct Domain {}
    struct Data {}
    struct Core {}
    struct UI {}
}

public extension TargetDependency.Feature {
    static let HomeFeature = TargetDependency.project(
        target: ModuleType.Feature.HomeFeature.targetName(type: .sources),
        path: .relativeToFeature(ModuleType.Feature.HomeFeature.rawValue)
    )
    
    static let FeedFeature = TargetDependency.project(
        target: ModuleType.Feature.FeedFeature.targetName(type: .sources),
        path: .relativeToFeature(ModuleType.Feature.FeedFeature.rawValue)
    )
}

public extension TargetDependency.Domain {
    static let RecommendationDomain = TargetDependency.project(
        target: ModuleType.Domain.RecommendationDomain.targetName(type: .sources),
        path: .relativeToDomain(ModuleType.Domain.RecommendationDomain.rawValue)
    )
    
    static let RecommendationDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.RecommendationDomain.targetName(type: .demo),
        path: .relativeToDomain(ModuleType.Domain.RecommendationDomain.rawValue)
    )
    
    static let RecommendationDomainTests = TargetDependency.project(
        target: ModuleType.Domain.RecommendationDomain.targetName(type: .tests),
        path: .relativeToDomain(ModuleType.Domain.RecommendationDomain.rawValue)
    )
}

public extension TargetDependency.Data {
    static let RecommendationData = TargetDependency.project(
        target: ModuleType.Data.RecommendationData.targetName(type: .sources),
        path: .relativeToDomain(ModuleType.Data.RecommendationData.rawValue)
    )
    
    static let RecommendationDataDemo = TargetDependency.project(
        target: ModuleType.Data.RecommendationData.targetName(type: .demo),
        path: .relativeToDomain(ModuleType.Data.RecommendationData.rawValue)
    )
    
    static let RecommendationDataTests = TargetDependency.project(
        target: ModuleType.Data.RecommendationData.targetName(type: .tests),
        path: .relativeToDomain(ModuleType.Data.RecommendationData.rawValue)
    )
}

public extension TargetDependency.Core {
    static let Keychain = TargetDependency.project(
        target: ModuleType.Core.Keychain.targetName(type: .sources),
        path: .relativeToCore(ModuleType.Core.Keychain.rawValue)
    )
    
    static let KeychainDemo = TargetDependency.project(
        target: ModuleType.Core.Keychain.targetName(type: .demo),
        path: .relativeToCore(ModuleType.Core.Keychain.rawValue)
    )
    
    static let Logger = TargetDependency.project(
        target: ModuleType.Core.Logger.targetName(type: .sources),
        path: .relativeToCore(ModuleType.Core.Logger.rawValue)
    )
    
    static let LoggerDemo = TargetDependency.project(
        target: ModuleType.Core.Logger.targetName(type: .demo),
        path: .relativeToCore(ModuleType.Core.Logger.rawValue)
    )
    
    static let Networking = TargetDependency.project(
        target: ModuleType.Core.Networking.targetName(type: .sources),
        path: .relativeToCore(ModuleType.Core.Networking.rawValue)
    )
    
    static let NetworkingDemo = TargetDependency.project(
        target: ModuleType.Core.Networking.targetName(type: .demo),
        path: .relativeToCore(ModuleType.Core.Networking.rawValue)
    )
    
    static let NetworkingTests = TargetDependency.project(
        target: ModuleType.Core.Networking.targetName(type: .tests),
        path: .relativeToCore(ModuleType.Core.Networking.rawValue)
    )
}

public extension TargetDependency.UI {
    static let DesignSystem = TargetDependency.project(
        target: ModuleType.UI.DesignSystem.targetName(type: .sources),
        path: .relativeToCore(ModuleType.UI.DesignSystem.rawValue)
    )
    
    static let WSSComponent = TargetDependency.project(
        target: ModuleType.UI.WSSComponent.targetName(type: .sources),
        path: .relativeToCore(ModuleType.UI.WSSComponent.rawValue)
    )
    
}
