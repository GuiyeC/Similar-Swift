//
//  Dispatcher.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

public protocol Dispatcher: AnyObject {
    func execute(_ request: Request) -> Task<Response>
}

public extension Task {
    func then(dispatcher: Dispatcher, _ requestBlock: @escaping (Output) -> Request) -> Task<Response> {
        return then { output in
            let request = requestBlock(output)
            return dispatcher.execute(request)
        }
    }
}
