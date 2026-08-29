//
//  AppURL.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱 전역에서 쓰는 외부 웹 링크 카탈로그. Feature는 Data를 import할 수 없어(App→Feature→Domain 단방향)
/// Feature가 직접 참조 가능한 BaseDomain에 둔다.
public enum AppURL: Sendable {
    /// 검색 결과에 없는 작품의 등록을 요청하는 노션 문의 폼.
    public static let inquiryAddNovel = URL(string: "https://helpwebsoso.notion.site/241a9688d1a38164b3f8efd0b51edaab?pvs=105")

    /// 오류 제보 노션 폼.
    public static let errorReport = URL(string: "https://helpwebsoso.notion.site/241a9688d1a381548c20dd314d0a0b0a")

    /// 공식 인스타그램.
    public static let instaURL = URL(string: "https://www.instagram.com/websoso_official/")

    /// 개인정보처리방침 노션 페이지.
    public static let privacyPolicy = URL(string: "https://websoso.notion.site/143600bd746880668556fb005fcef491?pvs=143")

    /// 서비스 이용약관 노션 페이지.
    public static let serviceAgreement = URL(string: "https://websoso.notion.site/143600bd74688050be18f4da31d9403e?pvs=4")

    /// 앱스토어 상품 페이지 — 공유 메시지의 "앱이 없다면 설치" 폴백(#228). 커스텀 스킴(`DeepLink`)은 미설치
    /// 기기에서 아무 데도 못 가므로 메시지 본문에 이 링크를 함께 실어 설치 경로를 준다. ID는
    /// `Config_Shared.xcconfig`의 `APPSTORE_ID`(운영 V1 앱)와 같은 값 — Feature는 App의 Info.plist를 못 읽고
    /// Demo엔 그 키가 없어 상수로 둔다. 컷오버 후에도 같은 앱을 대체하므로 값은 유지된다(`docs/TODO.md` 4절).
    public static let appStore = URL(string: "https://apps.apple.com/app/id6738299124")
}
