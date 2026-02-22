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
        target: ModuleType.Feature.home.targetName(type: .sources),
        path: .relativeToFeature(.home)
    )
    
    static let FeedFeature = TargetDependency.project(
        target: ModuleType.Feature.feed.targetName(type: .sources),
        path: .relativeToFeature(.feed)
    )
}

public extension TargetDependency.Domain {
    static let BaseDomain = TargetDependency.project(
        target: ModuleType.Domain.base.targetName(type: .sources),
        path: .relativeToDomain(.base)
    )
    
    static let BaseDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.base.targetName(type: .demo),
        path: .relativeToDomain(.base)
    )
    
    static let BaseDomainTests = TargetDependency.project(
        target: ModuleType.Domain.base.targetName(type: .tests),
        path: .relativeToDomain(.base)
    )
    
    static let RecommendationDomain = TargetDependency.project(
        target: ModuleType.Domain.recommendation.targetName(type: .sources),
        path: .relativeToDomain(.recommendation)
    )
    
    static let RecommendationDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.recommendation.targetName(type: .demo),
        path: .relativeToDomain(.recommendation)
    )
    
    static let RecommendationDomainTests = TargetDependency.project(
        target: ModuleType.Domain.recommendation.targetName(type: .tests),
        path: .relativeToDomain(.recommendation)
    )
    
    static let FeedDomain = TargetDependency.project(
        target: ModuleType.Domain.feed.targetName(type: .sources),
        path: .relativeToDomain(.feed)
    )

    static let FeedDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.feed.targetName(type: .demo),
        path: .relativeToDomain(.feed)
    )

    static let FeedDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.feed.targetName(type: .testing),
        path: .relativeToDomain(.feed)
    )

    static let FeedDomainTests = TargetDependency.project(
        target: ModuleType.Domain.feed.targetName(type: .tests),
        path: .relativeToDomain(.feed)
    )

    static let KeywordDomain = TargetDependency.project(
        target: ModuleType.Domain.keyword.targetName(type: .sources),
        path: .relativeToDomain(.keyword)
    )

    static let KeywordDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.keyword.targetName(type: .demo),
        path: .relativeToDomain(.keyword)
    )

    static let KeywordDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.keyword.targetName(type: .testing),
        path: .relativeToDomain(.keyword)
    )

    static let KeywordDomainTests = TargetDependency.project(
        target: ModuleType.Domain.keyword.targetName(type: .tests),
        path: .relativeToDomain(.keyword)
    )

    static let CommentDomain = TargetDependency.project(
        target: ModuleType.Domain.comment.targetName(type: .sources),
        path: .relativeToDomain(.comment)
    )

    static let CommentDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.comment.targetName(type: .demo),
        path: .relativeToDomain(.comment)
    )

    static let CommentDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.comment.targetName(type: .testing),
        path: .relativeToDomain(.comment)
    )

    static let CommentDomainTests = TargetDependency.project(
        target: ModuleType.Domain.comment.targetName(type: .tests),
        path: .relativeToDomain(.comment)
    )
    
    static let NovelDomain = TargetDependency.project(
        target: ModuleType.Domain.novel.targetName(type: .sources),
        path: .relativeToDomain(.novel)
    )
    
    static let NovelDomainDemo = TargetDependency.project(
        target: ModuleType.Domain.novel.targetName(type: .demo),
        path: .relativeToDomain(.novel)
    )
    
    static let NovelDomainTests = TargetDependency.project(
        target: ModuleType.Domain.novel.targetName(type: .tests),
        path: .relativeToDomain(.novel)
    )
    
    static let NovelDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.novel.targetName(type: .testing),
        path: .relativeToDomain(.novel)
    )

    static let NotificationDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.notification.targetName(type: .testing),
        path: .relativeToDomain(.notification)
    )

    static let NovelReviewDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.novelReview.targetName(type: .testing),
        path: .relativeToDomain(.novelReview)
    )

    static let SettingDomainTesting = TargetDependency.project(
        target: ModuleType.Domain.setting.targetName(type: .testing),
        path: .relativeToDomain(.setting)
    )
}

public extension TargetDependency.Data {
    static let RecommendationData = TargetDependency.project(
        target: ModuleType.Data.recommendation.targetName(type: .sources),
        path: .relativeToDomain(.recommendation)
    )
    
    static let RecommendationDataDemo = TargetDependency.project(
        target: ModuleType.Data.recommendation.targetName(type: .demo),
        path: .relativeToDomain(.recommendation)
    )
    
    static let RecommendationDataTests = TargetDependency.project(
        target: ModuleType.Data.recommendation.targetName(type: .tests),
        path: .relativeToDomain(.recommendation)
    )
}

public extension TargetDependency.Core {
    static let Keychain = TargetDependency.project(
        target: ModuleType.Core.keychain.targetName(type: .sources),
        path: .relativeToCore(.keychain)
    )
    
    static let KeychainDemo = TargetDependency.project(
        target: ModuleType.Core.keychain.targetName(type: .demo),
        path: .relativeToCore(.keychain)
    )
    
    static let KeychainTests = TargetDependency.project(
        target: ModuleType.Core.keychain.targetName(type: .tests),
        path: .relativeToCore(.keychain)
    )
    
    static let Logger = TargetDependency.project(
        target: ModuleType.Core.logger.targetName(type: .sources),
        path: .relativeToCore(.logger)
    )
    
    static let LoggerDemo = TargetDependency.project(
        target: ModuleType.Core.logger.targetName(type: .demo),
        path: .relativeToCore(.logger)
    )
    
    static let Networking = TargetDependency.project(
        target: ModuleType.Core.networking.targetName(type: .sources),
        path: .relativeToCore(.networking)
    )
    
    static let NetworkingDemo = TargetDependency.project(
        target: ModuleType.Core.networking.targetName(type: .demo),
        path: .relativeToCore(.networking)
    )
    
    static let NetworkingTests = TargetDependency.project(
        target: ModuleType.Core.networking.targetName(type: .tests),
        path: .relativeToCore(.networking)
    )
}

public extension TargetDependency.UI {
    static let DesignSystem = TargetDependency.project(
        target: ModuleType.UI.designSystem.targetName(type: .sources),
        path: .relativeToUI(.designSystem)
    )
    
    static let WSSComponent = TargetDependency.project(
        target: ModuleType.UI.wssComponent.targetName(type: .sources),
        path: .relativeToUI(.wssComponent)
    )
}
