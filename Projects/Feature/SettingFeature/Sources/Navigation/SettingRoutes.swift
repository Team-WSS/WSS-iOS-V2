//
//  SettingRoutes.swift
//  SettingFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

// 설정 트리의 화면별 화면 전환 의도(#253) — 실제 화면 조립·push는 호출자(App 조정 계층)가
// exhaustive switch로 수행한다. 세션 이벤트(`onLogoutSuccess`/`onWithdrawSuccess` — App 쪽 딥링크
// 복원 여부가 갈리는 별도 계약)와 저장 결과(`onSaveSuccess`)·확정(`onConfirm`)은 화면 전환
// "의도"가 아니라 여기 없다.

/// 설정 메인 목록(`SettingView`).
public enum SettingRoute {
    /// 계정 정보 — "계정 정보" 행.
    case accountInfo
    /// 프로필 공개 설정 — "프로필 공개 설정" 행.
    case profilePublicSetting
    /// 알림 설정 — "알림 설정" 행(denied면 이동 없이 알럿 — 그 판단은 화면이 유지).
    case notificationSetting
}

/// 계정 정보(`SettingAccountInfoView`).
public enum SettingAccountInfoRoute {
    /// 성별/나이 변경 — "성별/나이" 행.
    case changeGenderOrAge
    /// 차단 유저 목록 — "차단 유저 목록" 행.
    case blockUserList
    /// 회원탈퇴 플로우 — "회원탈퇴" 행.
    case withdraw
}

/// 알림 설정(`NotificationSettingView`).
public enum NotificationSettingRoute {
    /// 완결 알림 작품 목록.
    case completionNotificationList
    /// 휴재 복귀 알림 작품 목록.
    case hiatusReturnNotificationList
}

/// 완결/휴재 복귀 알림 작품 목록(`NovelNotificationListView` — 두 진입점이 화면을 공유).
public enum NovelNotificationListRoute {
    /// 작품 둘러보기 — 빈 상태 CTA. 검색 화면은 다른 Feature 모듈이라 이 화면이 직접 못 연다 —
    /// 현재 App은 일반 검색으로 매핑한다(`MyLibraryRoute.search`와 같은 결).
    case browseNovels
}
