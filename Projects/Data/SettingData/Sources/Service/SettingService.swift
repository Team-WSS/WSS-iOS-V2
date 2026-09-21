//
//  SettingService.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

protocol SettingService: Sendable {
    
    // MARK: - Term
    
    func getTermSetting() async throws -> TermSettingResponse
    func patchTermSetting(_ request: TermSettingRequest) async throws
    
    // MARK: - ForceUpdate
    
    func getAppMinimumVersion(query: AppMinimumVersionQuery) async throws -> AppMinimumVersionResponse
}
