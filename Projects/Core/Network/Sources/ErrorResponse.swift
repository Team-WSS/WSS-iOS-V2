//
//  ErrorResponse.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public struct ErrorResponse: Codable {
    public let code: String
    public let message: String
}

