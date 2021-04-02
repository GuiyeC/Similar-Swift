//
//  Request.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

public struct Request {
    public enum Data {
        case data(Foundation.Data)
        case json(Encodable, encoder: JSONEncoder = Similar.defaultEncoder)
        case multipart([DataPart])
    }

    public struct DataPart {
        let name: String
        let filename: String?
        let mimeType: String?
        let data: Foundation.Data
        
        public init(name: String,
                    filename: String? = nil,
                    mimeType: String? = nil,
                    data: Foundation.Data) {
            self.name = name
            self.filename = filename
            self.mimeType = mimeType
            self.data = data
        }
        
        public init(name: String,
                    filename: String? = nil,
                    mimeType: String? = nil,
                    data: String,
                    encoding: String.Encoding = .utf8) {
            self.name = name
            self.filename = filename
            self.mimeType = mimeType
            self.data = data.data(using: .utf8)!
        }
    }
    
    public init(_ path: String,
                method: HttpMethod = .get,
                expectedCode: Range<Int> = (200..<300),
                headers: [String: String]? = nil,
                parameters: [String: AnyHashable]? = nil,
                data: Data? = nil) {
        self.path = path
        self.method = method
        self.expectedCode = expectedCode
        self.headers = headers
        self.parameters = parameters
        self.data = data
    }
    
    public init(_ path: String,
                method: HttpMethod = .get,
                expectedCode: Range<Int> = (200..<300),
                headers: [String: String]? = nil,
                parameters: [String: AnyHashable]? = nil,
                data: Encodable?,
                encoder: JSONEncoder = Similar.defaultEncoder) {
        self.path = path
        self.method = method
        self.expectedCode = expectedCode
        self.headers = headers
        self.parameters = parameters
        self.data = data.map { .json($0, encoder: encoder) }
    }
    
    public var path: String
    public var method: HttpMethod
    public var expectedCode: Range<Int>
    public var headers: [String: String]?
    public var parameters: [String: AnyHashable]?
    public var data: Data?
}

extension Request: CustomStringConvertible {
    public var description: String {
        var description = "\(method.rawValue) '\(path)'"
        if let parameters = parameters {
            description.append("\nParameters: [")
            parameters.forEach { description.append("  \($0.key): \($0.value)") }
            description.append("]")
        }
        if let headers = headers {
            description.append("\nHeaders: [")
            headers.forEach { description.append("  \($0.key): \($0.value)") }
            description.append("]")
        }
        switch data {
        case .data(let data):
            description.append("\nRaw data: \(String(data: data, encoding: .utf8) ?? String(describing: data))")
        case .json:
            do {
                let encodedData = try data!.rawData()
                let formattedJson = try JSONSerialization.jsonObject(with: encodedData)
                description.append("\nJSON Data: \(String(describing: formattedJson))")
            } catch {
                description.append("\nJSON Data: Unencodable data")
            }
        case .multipart(let parts):
            description.append("\nMultipart: [")
            parts.forEach { description.append("  \(String(describing: $0))") }
            description.append("]")
        case .none: break
        }
        return description
    }
}
