//
//  NetworkDispatcher.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

open class NetworkDispatcher: Dispatcher {
    let session: URLSession
    lazy var progressTokens: [Int: NSKeyValueObservation] = [:]
    
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
        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
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
        if #available(iOS 11.0, macOS 10.13, *) {
            progressTokens[dataTask.taskIdentifier] = dataTask.progress.observe(\.fractionCompleted) { [weak task] value, _ in
                task?.progress = value.fractionCompleted
            }
            task.always { [weak self] in self?.progressTokens.removeValue(forKey: dataTask.taskIdentifier) }
        }
        task.cancelBlock = dataTask.cancel
        dataTask.resume()
        return task
    }
}

fileprivate extension URLRequest {
    mutating func setData(_ data: Request.Data?) throws {
        httpBody = try data?.rawData()
        switch data {
        case .data:
            break
        case .json:
            setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(_, let boundaryId):
            let boundary = "Boundary-\(boundaryId)"
            setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        case .none:
            break
        }
    }
}

extension Request.Data {
    func rawData() throws -> Data {
        switch self {
        case .data(let data):
            return data
        case .json(let jsonData, let encoder):
            return try jsonData.encode(encoder)
        case .multipart(let parts, let boundaryId):
            let boundary = "Boundary-\(boundaryId)"
            let multipartData = NSMutableData()
            for part in parts {
                multipartData.appendString("--\(boundary)\r\n")
                multipartData.appendString("Content-Disposition: form-data; name=\"\(part.name)\"")
                if let filename = part.filename {
                    multipartData.appendString("; filename=\"\(filename)\"")
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
            return multipartData as Data
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
