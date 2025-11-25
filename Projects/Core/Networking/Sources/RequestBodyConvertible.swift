//
//  RequestBodyConvertible.swift
//  Networking
//
//  Created by YunhakLee on 11/24/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol RequestBodyConvertible: Encodable {
    func asRequestBody() -> Data?
}

public extension RequestBodyConvertible {
    func asRequestBody() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
}
