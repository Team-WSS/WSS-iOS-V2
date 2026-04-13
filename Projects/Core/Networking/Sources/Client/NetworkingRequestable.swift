//
//  Networking.swift
//  Network
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public protocol NetworkingRequestable {
    func request(_ endPoint: Endpoint) async throws -> Data
}
