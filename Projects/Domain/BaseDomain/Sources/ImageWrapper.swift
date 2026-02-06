//
//  ImageWrapper.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ImageWrapper: Equatable {
    public let identifier: String
    
    public init(identifier: String) {
        self.identifier = identifier
    }
}
