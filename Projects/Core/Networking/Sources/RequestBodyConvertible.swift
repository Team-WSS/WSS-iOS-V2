//
//  RequestBodyConvertible.swift
//  Networking
//
//  Created by YunhakLee on 11/24/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

protocol RequestBodyConvertible: Encodable {
    func asRequestBody() -> Data?
}

extension RequestBodyConvertible {
    func asRequestBody() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
}
