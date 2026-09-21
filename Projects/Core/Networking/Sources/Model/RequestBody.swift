//
//  RequestBody.swift
//  Networking
//
//  Created by YunhakLee on 11/24/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

public enum RequestBody {
    case none
    case json(any Encodable)
    case multipart(MultipartFormData)
}

public struct MultipartFormData {
    public let boundary: String
    public let parts: [MultipartFormDataPart]

    public init(
        boundary: String = UUID().uuidString,
        parts: [MultipartFormDataPart]
    ) {
        self.boundary = boundary
        self.parts = parts
    }
}

public enum ContentType: Equatable {
    case json
    case text
    case jpeg
    case png
    case heic
    case custom(headerValue: String, fileExtension: String?)
}

public enum MultipartFormDataPart {
    case json(keyName: String, value: any Encodable)
    case text(keyName: String, value: String)
    case imageData(
        keyName: String,
        data: Data,
        contentType: ContentType = .jpeg,
        fileName: String? = nil
    )
    case data(
        keyName: String,
        data: Data,
        contentType: ContentType,
        fileName: String? = nil
    )
}

struct EncodedRequestBody {
    let data: Data?
    let contentType: String?
}

extension RequestBody {
    func encoded() throws -> EncodedRequestBody {
        do {
            switch self {
            case .none:
                return EncodedRequestBody(data: nil, contentType: nil)
            case .json(let value):
                let data = try JSONEncoder().encode(AnyEncodable(value))
                return EncodedRequestBody(data: data, contentType: ContentType.json.headerValue)
            case .multipart(let formData):
                return try formData.encoded()
            }
        } catch let error as NetworkingError {
            throw error
        } catch {
            throw NetworkingError.requestEncodingFailed(error)
        }
    }
}

extension MultipartFormData {
    func encoded() throws -> EncodedRequestBody {
        var data = Data()

        for part in parts {
            data.append("--\(boundary)\r\n")
            try part.append(to: &data)
        }

        data.append("--\(boundary)--\r\n")

        return EncodedRequestBody(
            data: data,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
}

private extension MultipartFormDataPart {
    func append(to data: inout Data) throws {
        switch self {
        case .json(let keyName, let value):
            let body = try JSONEncoder().encode(AnyEncodable(value))
            appendPartHeader(
                to: &data,
                keyName: keyName,
                contentType: ContentType.json.headerValue
            )
            data.append(body)
            data.append("\r\n")
        case .text(let keyName, let value):
            appendPartHeader(
                to: &data,
                keyName: keyName,
                contentType: ContentType.text.headerValue
            )
            data.append(value)
            data.append("\r\n")
        case .imageData(let keyName, let imageData, let contentType, let fileName):
            appendPartHeader(
                to: &data,
                keyName: keyName,
                fileName: fileName ?? contentType.defaultFileName(prefix: "image"),
                contentType: contentType.headerValue
            )
            data.append(imageData)
            data.append("\r\n")
        case .data(let keyName, let bodyData, let contentType, let fileName):
            appendPartHeader(
                to: &data,
                keyName: keyName,
                fileName: fileName ?? contentType.defaultFileName(prefix: "file"),
                contentType: contentType.headerValue
            )
            data.append(bodyData)
            data.append("\r\n")
        }
    }

    func appendPartHeader(
        to data: inout Data,
        keyName: String,
        fileName: String? = nil,
        contentType: String
    ) {
        var disposition = "Content-Disposition: form-data; name=\"\(keyName.headerEscaped)\""
        if let fileName {
            disposition += "; filename=\"\(fileName.headerEscaped)\""
        }

        data.append("\(disposition)\r\n")
        data.append("Content-Type: \(contentType)\r\n\r\n")
    }
}

extension ContentType {
    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .text:
            return "text/plain"
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .heic:
            return "image/heic"
        case .custom(let headerValue, _):
            return headerValue
        }
    }

    var fileExtension: String? {
        switch self {
        case .json:
            return "json"
        case .text:
            return "txt"
        case .jpeg:
            return "jpeg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .custom(_, let fileExtension):
            return fileExtension
        }
    }

    func defaultFileName(prefix: String) -> String {
        guard let fileExtension,
              fileExtension.isEmpty == false else {
            return prefix
        }

        return "\(prefix).\(fileExtension.trimmedLeadingDot)"
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encodeClosure = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}

private extension String {
    var headerEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    var trimmedLeadingDot: String {
        hasPrefix(".") ? String(dropFirst()) : self
    }
}
