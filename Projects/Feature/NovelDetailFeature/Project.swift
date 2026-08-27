//
//  Project.swift
//  Manifests
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.novelDetail).name,
    targets: [.sources, .demo, .tests],
    // 전용 NovelDetailDomain은 없다 — 소설 상세는 NovelDomain의 UseCase를 쓴다(#154).
    // 피드 탭이 이슈 범위에 포함되어 FeedDomain(목록·좋아요·삭제)도,
    // 평가 삭제가 포함되어 NovelReviewDomain(DeleteNovelReviewUseCase)도,
    // 피드 신고가 포함되어 SocialDomain(Report*FeedUseCase)도,
    // 작품 알림 등록 시트가 포함되어 NotificationDomain(NovelNotificationSetting)도 의존한다(#189).
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.novel)),
        .module(.domain(.feed)),
        .module(.domain(.novelReview)),
        .module(.domain(.social)),
        .module(.domain(.notification)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.novel)),
        .module(.data(.feed)),
        .module(.data(.novelReview)),
        .module(.data(.social)),
        .module(.data(.notification)),
        .module(.data(.base)),
        .module(.core(.networking))
    ],
    // TopBounceDisabler의 contentOffset KVO 경고 3건이 assumeIsolated로 해결되지 않는다
    // (경고는 없어지지만 상단 클램프 동작이 깨짐 → docs/TODO.md 4번). 그래서 이 모듈만
    // mode 6 승격에서 제외한다. 나머지 11개 Feature는 기본값(enableSwift6: true).
    enableSwift6: false
)
