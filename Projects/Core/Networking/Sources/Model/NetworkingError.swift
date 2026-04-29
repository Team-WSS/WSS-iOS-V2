//
//  NetworkError.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public enum NetworkingError: Error, CustomStringConvertible {
    case invalidURL
    case decoding
    case responseFailure(code: Int, body: ErrorResponse?)
    case requiresReauthentication
    case unknown(Error)
    
    public var description: String {
        switch self {
        case .invalidURL:
            return "🌐 [NetworkError] Invalid URL"
        case .decoding:
            return "🌐 [NetworkError] JSON Decoding Failed"
        case .responseFailure(let code, let body):
            if let body {
                return "🌐 [NetworkError] HTTP \(code) - \(body.code): \(body.message)"
            } else {
                return "🌐 [NetworkError] HTTP \(code) - No body in response"
            }
        case .requiresReauthentication:
            return "🌐 [NetworkError] Reauthentication Required"
        case .unknown(let error):
            return "🌐 [NetworkError] Unknown Error: \(error.localizedDescription)"
        }
    }
}
