//
//  SubmitState.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public enum SubmitState: Equatable {
    case idle
    case submitting
    case submitted
    case failed(RepositoryError)
}
