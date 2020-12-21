//
//  NetworkDispatcher.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

open class NetworkDispatcher: Dispatcher {
    let session: URLSession
    
    public init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
    open func execute(_ request: Request) -> Task<Response> {
        let url: URL?
        if let parameters = request.parameters, var urlComponents = URLComponents(string: request.path) {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0, value: String(describing: $1)) }
            url = urlComponents.url
        } else {
            url = URL(string: request.path)
        }
        guard let validUrl = url else {
            fatalError("Invalid URL")
        }
        var urlRequest = URLRequest(url: validUrl)
        urlRequest.httpMethod = request.method.rawValue
        var requestHeaders = request.headers ?? [:]
        requestHeaders["Accept"] = "application/json"
        urlRequest.allHTTPHeaderFields = requestHeaders
        let task = Task<Response>()
        do {
            try urlRequest.setData(request.data)
        } catch {
            task.fail(.localError(error))
            return task
        }
        print("Url:", validUrl)
        print(requestHeaders)
        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
            data.map { data in String(data: data, encoding: .utf8).map { print("Data:", $0) } }
            if let error = error {
                print("Error:", error)
                task.fail(.localError(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                task.fail(.noData)
                return
            }
            guard request.expectedCode ~= response.statusCode else {
                task.fail(.serverError(code: response.statusCode, data))
                return
            }
            guard let data = data else {
                task.fail(.noData)
                return
            }
            task.complete(Response(data: data, response: response))
        }
        task.cancelBlock = dataTask.cancel
        dataTask.resume()
        return task
    }
}

fileprivate extension URLRequest {
    mutating func setData(_ data: Request.Data?) throws {
        switch data {
        case .data(let data):
            httpBody = data
        case .json(let jsonData, let encoder):
            setValue("application/json", forHTTPHeaderField: "Content-Type")
            httpBody = try jsonData.encode(encoder)
        case .multipart(let parts):
            let boundary = "Boundary-\(UUID().uuidString)"
            setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let multipartData = NSMutableData()
            for part in parts {
                multipartData.appendString("--\(boundary)\r\n")
                multipartData.appendString("Content-Disposition: form-data; name=\"\(part.name)\"")
                if let fileName = part.fileName {
                    multipartData.appendString("; filename=\"\(fileName)\"")
                }
                multipartData.appendString("\r\n")
                if let mimeType = part.mimeType {
                    multipartData.appendString("Content-Type: \(mimeType)\r\n")
                }
                multipartData.appendString("\r\n")
                multipartData.append(part.data)
                multipartData.appendString("\r\n")
            }
            multipartData.appendString("--\(boundary)\r\n")
            httpBody = multipartData as Data
        case .none:
            httpBody = nil
        }
    }
}

fileprivate extension NSMutableData {
    func appendString(_ string: String) {
        string.data(using: .utf8).map { append($0) }
    }
}

fileprivate extension Encodable {
    func encode(_ encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self)
    }
}
