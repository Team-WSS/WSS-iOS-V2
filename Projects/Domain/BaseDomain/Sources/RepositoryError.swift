//
//  RepositoryError.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum RepositoryError: Error, Equatable {
    case networkUnavailable
    case authenticationRequired
    case serverUnavailable
    case notFound
    case invalidData
    case unknown
}
