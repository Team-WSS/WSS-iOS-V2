//
//  RepositoryError.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum RepositoryError: Error, Equatable {
    case networkUnavailable
    case authenticationRequired
    case serverUnavailable
    case notFound
    case unknown
}
