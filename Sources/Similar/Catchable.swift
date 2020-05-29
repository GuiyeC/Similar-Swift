//
//  Catchable.swift
//  Similar
//
//  Created by Guillermo Cique Fernández on 29/05/2020.
//

import Foundation

public protocol Catchable {
    @discardableResult
    func `catch`(queue: DispatchQueue?, _ block: @escaping ((RequestError) -> Void)) -> Self
}

public extension Catchable {
    @discardableResult
    func `catch`(_ block: @escaping ((RequestError) -> Void)) -> Self { self.catch(queue: nil, block) }
}
