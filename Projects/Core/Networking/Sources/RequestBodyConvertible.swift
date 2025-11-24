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
        // 나중에 여기서 공통 encoder, date 전략, key 전략 등도 통일 가능
        try? JSONEncoder().encode(self)
    }
    
}
