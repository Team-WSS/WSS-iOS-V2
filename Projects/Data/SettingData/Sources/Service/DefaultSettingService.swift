//
//  DefaultSettingService.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct DefaultSettingService: SettingService {
    private let client: NetworkingRequestable
    
    init(client: NetworkingRequestable) {
        self.client = client
    }
    
    // MARK: - Term
    
    func getTermSetting() async throws -> TermSettingResponse {
        let endpoint = SettingEndpoint.getTermSetting
        return try await client.request(endpoint, decodeTo: TermSettingResponse.self)
    }
    
    func patchTermSetting(_ request: TermSettingRequest) async throws {
        let endpoint = SettingEndpoint.patchTermSetting(request)
        _  = try await client.request(endpoint)
    }
    
    // MARK: - ForceUpdate
    
    func getAppMinimumVersion() async throws -> AppMinimumVersionResponse {
        let endpoint = SettingEndpoint.getAppMinimumVersion
        return try await client.request(endpoint, decodeTo: AppMinimumVersionResponse.self)
    }
}
