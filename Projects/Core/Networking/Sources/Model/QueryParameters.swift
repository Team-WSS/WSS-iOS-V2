//
//  QueryParameters.swift
//  Networking
//
//  Created by YunhakLee on 4/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum QueryParameters {
    case none
    case convertible(any QueryItemConvertible)
    case custom([URLQueryItem])

    public var queryItems: [URLQueryItem]? {
        switch self {
        case .none:
            return nil
        case .convertible(let value):
            return value.asQueryItems()
        case .custom(let items):
            return items
        }
    }
}

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
            if let bool = asQueryBool(value) {
                return URLQueryItem(name: key, value: bool ? "true" : "false")
            }

            // 3) 배열인 경우: 요소별로 다시 한 번 타입 체크 후 ","로 join
            if let array = value as? [Any] {
                let joined = array.compactMap { element -> String? in
                    // 배열 안의 null도 제거
                    if element is NSNull { return nil }

                    if let boolElement = asQueryBool(element) {
                        return boolElement ? "true" : "false"
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

private func asQueryBool(_ value: Any) -> Bool? {
    guard let number = value as? NSNumber,
          CFGetTypeID(number) == CFBooleanGetTypeID() else {
        return nil
    }

    return number.boolValue
}
