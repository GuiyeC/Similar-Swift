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
        let mimeType: String?
        let fileName: String?
        let data: Foundation.Data
        
        public init(name: String, mimeType: String, fileName: String, data: Foundation.Data) {
            self.name = name
            self.mimeType = mimeType
            self.fileName = fileName
            self.data = data
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
