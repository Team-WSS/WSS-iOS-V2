//
//  Networking+Helper.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public extension NetworkRequestable {
    func request<T: Decodable>(
        _ endPoint: Endpoint,
        decodeTo type: T.Type
    ) async throws -> T {
        let data = try await request(endPoint)
        return try JSONDecoder().decode(type, from: data)
    }
}
