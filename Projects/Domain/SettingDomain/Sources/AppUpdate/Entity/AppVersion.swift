//
//  AppVersion.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// Semantic-ish version: "1.2.3" 형태를 비교 가능하게 만드는 VO
public struct AppVersion: Equatable, Comparable, Hashable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String { "\(major).\(minor).\(patch)" }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// "1", "1.2", "1.2.3" 모두 허용. 그 외는 throw.
    /// 빈 자리("1..2", "1.", ".1")도 throw — 빈 자리를 버리고 나누면 "1..2"가 1.2.0으로 조용히 읽힌다.
    /// 빈 문자열은 `[""]`로 나뉘어 숫자 변환에서 throw되므로 따로 검사하지 않는다.
    public init(_ string: String) throws {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false).map { String($0) }
        guard (1...3).contains(parts.count) else { throw ParseError.invalidFormat(string) }

        func parse(_ idx: Int) throws -> Int {
            guard idx < parts.count else { return 0 }
            guard let v = Int(parts[idx]), v >= 0 else { throw ParseError.invalidFormat(string) }
            return v
        }

        self.major = try parse(0)
        self.minor = try parse(1)
        self.patch = try parse(2)
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case invalidFormat(String)

        public var description: String {
            switch self {
            case .invalidFormat(let s):
                return "Invalid version format: \(s)"
            }
        }
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}