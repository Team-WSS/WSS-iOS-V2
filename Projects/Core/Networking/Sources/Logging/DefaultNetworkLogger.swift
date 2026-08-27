//
//  DefaultNetworkLogger.swift
//  Networking
//
//  Created by YunhakLee on 10/31/25.
//

import Foundation
import Logger

public final class DefaultNetworkLogger: NetworkLogging, Sendable {
    private let base: Logger
    private let showBody: Bool
    private let showHost: Bool

    public init(
        base: Logger,
        showBody: Bool = true,
        showHost: Bool = false
    ) {
        self.base = base
        self.showBody = showBody
        self.showHost = showHost
    }

    public func logRequest(_ request: URLRequest) {
        let urlText = describe(url: request.url)

        var message = """
        🌐 [REQUEST]
        - method: \(request.httpMethod ?? "nil")
        - url: \(urlText)
        - headers: \(redacted(request.allHTTPHeaderFields))
        """

        if showBody,
           let body = formattedBody(from: request.httpBody) {
            message += "\n- body:\n\(body)"
        }

        base.debug(message)
    }

    public func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error {
            base.error("❌ [RESPONSE ERROR] \(error)")
            return
        }

        guard let http = response as? HTTPURLResponse else {
            base.error("❌ [RESPONSE] not HTTPURLResponse")
            return
        }

        let urlText = describe(url: http.url)

        var message = """
        🌐 [RESPONSE]
        - status: \(http.statusCode)
        - url: \(urlText)
        """

        if showBody,
           let body = formattedBody(from: data) {
            message += "\n- body:\n\(body)"
        }

        if (200..<300).contains(http.statusCode) {
            base.info(message)
        } else {
            base.error(message)
        }
    }

    // MARK: - helpers

    private func describe(url: URL?) -> String {
        guard let url else { return "nil" }
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        if !showHost {
            var path = comps.path
            if let query = comps.query, !query.isEmpty {
                path += "?\(query)"
            }
            return path.isEmpty ? "/" : path
        }

        return url.absoluteString
    }

    private func redacted(_ headers: [String: String]?) -> [String: String] {
        guard let headers else { return [:] }
        var new: [String: String] = [:]
        for (key, value) in headers {
            if key.lowercased().contains("authorization") {
                new[key] = "🔒 <redacted>"
            } else {
                new[key] = value
            }
        }
        return new
    }

    private func formattedBody(from data: Data?) -> String? {
        guard let data,
              let body = String(data: data, encoding: .utf8),
              !body.isEmpty else {
            return nil
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: jsonObject,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyBody = String(data: prettyData, encoding: .utf8) else {
            return body
        }

        return prettyBody
    }
}
