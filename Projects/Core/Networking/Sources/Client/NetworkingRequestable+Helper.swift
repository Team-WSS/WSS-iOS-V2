//
//  Networking+Helper.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public extension NetworkingRequestable {
    func request<T: Decodable>(
        _ endPoint: Endpoint,
        decodeTo type: T.Type
    ) async throws -> T {
        let data = try await request(endPoint)
        do {
            return try JSONDecoder().decode(type, from: data)
        }
        catch {
            throw NetworkingError.decoding
        }
    }
}
