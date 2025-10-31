//
//  Logger.swift
//  Logger
//
//  Created by YunhakLee on 10/31/25.
//

import Foundation

public protocol Logger {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String)
}
