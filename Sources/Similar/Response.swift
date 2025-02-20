//
//  File.swift
//  
//
//  Created by Guillermo Cique Fernández on 21/12/20.
//

import Foundation

public struct Response: Sendable {
    public let data: Data
    public let statusCode: Int
    public let headers: [String: String]
    
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.statusCode = response.statusCode
        self.headers = response.allHeaderFields.reduce(into: [String: String]()) { (result, entry) in
            result[String(describing: entry.key)] = String(describing: entry.value)
        }
    }
    
    public init(data: Data, statusCode: Int, headers: [String: String] = [:]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}
