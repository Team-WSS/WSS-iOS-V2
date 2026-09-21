//
//  KeychainStoring+Helper.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

// MARK: - String Helpers
public extension KeychainStore {
    func create(value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataEncodingFailed
        }
        try create(data: data, forKey: key)
    }

    func value(forKey key: String) throws -> String? {
        guard let data = try read(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func update(value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataEncodingFailed
        }
        try update(data: data, forKey: key)
    }

    func save(value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataEncodingFailed
        }
        try save(data: data, forKey: key)
    }
}

// MARK: - Codable Helpers
public extension KeychainStore {
    func create<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try create(data: data, forKey: key)
    }

    func value<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = try read(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func update<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try update(data: data, forKey: key)
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try save(data: data, forKey: key)
    }
}
