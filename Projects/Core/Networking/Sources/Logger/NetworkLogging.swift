//
//  NetworkLogging.swift
//  Networking
//
//  Created by YunhakLee on 10/31/25.
//

import Foundation

public protocol NetworkLogging {
    func logRequest(_ request: URLRequest)
    func logResponse(data: Data?, response: URLResponse?, error: Error?)
}
