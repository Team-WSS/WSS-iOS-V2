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

    /// 앱스토어 상세 페이지(강제 업데이트 알럿 → 이동). V1과 같은 앱 레코드 ID이며,
    /// 컷오버도 같은 레코드로 업로드하는 계획이라(docs/TODO.md 4절) ID가 유지된다.
    public static let appStore = URL(string: "itms-apps://itunes.apple.com/kr/app/id6738299124")
}
