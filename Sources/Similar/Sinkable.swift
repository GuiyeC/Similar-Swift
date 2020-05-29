//
//  Sinkable.swift
//  Similar
//
//  Created by Guillermo Cique Fernández on 29/05/2020.
//

import Foundation

public protocol Sinkable {
    associatedtype Output
    func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self
}

public extension Sinkable {
    @discardableResult
    func sink(_ block: @escaping ((Output) -> Void)) -> Self { sink(queue: nil, block) }
    
    @discardableResult
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Self {
        assign(to: keyPath, on: object, queue: nil)
    }
    
    @discardableResult
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root, queue: DispatchQueue?) -> Self {
        sink(queue: queue) { [weak object] data in
            object?[keyPath: keyPath] = data
        }
    }
    
    @discardableResult
    func print() -> Self {
        sink { Swift.print(String(describing: $0)) }
    }
}
