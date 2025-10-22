//
//  Networking.swift
//  Network
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public protocol Networking {
    var basicURLSession: URLSession { get }
    
    var tokenCheckURLSession: URLSession { get }
    
    func makeHTTPRequest(
        method: HTTPMethod,
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]?,
        headers: [String: String]?,
        body: Data?) throws -> URLRequest
    
    func makeMultipartBody(keyName: String,
                           images: [Data],
                           boundary: String,
                           fileName: String,
                           mimeType: String) -> Data
    
    func validataDataResponse<T: Decodable> (_ data: Data, response: URLResponse, to target: T.Type) throws -> T
}
