//
//  QueryItemConvertible.swift
//  Networking
//
//  Created by YunhakLee on 11/24/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol QueryItemConvertible: Encodable {
    func asQueryItems() -> [URLQueryItem]
}

public extension QueryItemConvertible {
    func asQueryItems() -> [URLQueryItem] {
        // Encodable -> Data -> [String: Any]
        guard let data = try? JSONEncoder().encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        return jsonObject.compactMap { key, value in
            // 1) Optional nil(jsonObject에서는 NSNull)인 값은 쿼리에서 제외
            if value is NSNull {
                return nil
            }

            // 2) Bool은 항상 "true"/"false"로
            //    NSNumber(1) as? Bool 이 성공하므로 CFBoolean 타입으로 구분
            if isBoolNSNumber(value), let bool = value as? Bool {
                return URLQueryItem(name: key, value: bool ? "true" : "false")
            }

            // 3) 배열인 경우: 요소별로 다시 한 번 타입 체크 후 ","로 join
            if let array = value as? [Any] {
                let joined = array.compactMap { element -> String? in
                    // 배열 안의 null도 제거
                    if element is NSNull { return nil }

                    if isBoolNSNumber(element), let b = element as? Bool {
                        return b ? "true" : "false"
                    }

                    return String(describing: element)
                }.joined(separator: ",")
                return URLQueryItem(name: key, value: joined)
            }

            // 4) 나머지 단일 값(Int, String 등)은 문자열로 변환
            return URLQueryItem(name: key, value: String(describing: value))
        }
    }
}

// NSNumber(value: 1) as? Bool 이 성공하기 때문에 CFBoolean 타입 ID로 실제 Bool 여부를 확인
private func isBoolNSNumber(_ value: Any) -> Bool {
    guard let n = value as? NSNumber else { return false }
    return CFGetTypeID(n) == CFBooleanGetTypeID()
}
