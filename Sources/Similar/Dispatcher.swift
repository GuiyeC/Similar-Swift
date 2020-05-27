//
//  Dispatcher.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

public protocol Dispatcher: class {
    func execute(_ request: Request) -> Task<Data>
}

public extension Task {
    func then(dispatcher: Dispatcher, _ requestBlock: @escaping (Output) -> Request) -> Task<Data> {
        return then { output in
            let request = requestBlock(output)
            return dispatcher.execute(request)
        }
    }
}
