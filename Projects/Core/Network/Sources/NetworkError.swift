//
//  NetworkError.swift
//  Network
//
//  Created by YunhakLee on 10/28/25.
//

import Foundation

public enum NetworkError: Error, CustomStringConvertible {
    case invalidURL
    case decoding
    case encoding
    case emptyData
    case responseFailure(code: Int, body: ErrorResponse?)
    case unknown(Error)

    public var description: String {
        switch self {
        case .invalidURL:
            return "🌐 [NetworkError] Invalid URL"
        case .decoding:
            return "🌐 [NetworkError] JSON Decoding Failed"
        case .encoding:
            return "🌐 [NetworkError] Request Body Encoding Failed"
        case .emptyData:
            return "🌐 [NetworkError] No Data Returned"
        case .responseFailure(let code, let body):
            if let body {
                return "🌐 [NetworkError] HTTP \(code) - \(body.code): \(body.message)"
            } else {
                return "🌐 [NetworkError] HTTP \(code) - No body in response"
            }
        case .unknown(let error):
            return "🌐 [NetworkError] Unknown Error: \(error.localizedDescription)"
        }
    }
}
