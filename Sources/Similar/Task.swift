//
//  Task.swift
//  Similar
//
//  Created by Guillermo Cique on 08/02/2020.
//

import Foundation

public protocol Cancellable {
    func cancel()
}

public class Task<Output>: Sinkable, Catchable, Cancellable {
    public private(set) var isCancelled: Bool = false
    public var cancelBlock: (() -> Void)?
    var blocks: [Any] = []
    private(set) var output: Output? {
        didSet {
            guard oldValue == nil, error == nil, let output = output else {
                preconditionFailure("Invalid output value")
            }
            guard !isCancelled else { return }
            executeCompletion(with: output)
            clearBlocks()
        }
    }
    private(set) var error: RequestError? {
        didSet {
            guard output == nil, oldValue == nil, let error = error else {
                preconditionFailure("Invalid error value")
            }
            guard !isCancelled else { return }
            executeError(with: error)
            clearBlocks()
        }
    }
    
    public init() {}
    
    public init(output: Output) {
        complete(output)
    }
    
    public init(error: RequestError) {
        fail(error)
    }
    
    public func complete(_ output: Output) {
        self.output = output
    }
    
    public func fail(_ error: RequestError) {
        self.error = error
    }
    
    func executeCompletion(with output: Output) {
        for block in blocks {
            switch block {
            case let block as (() -> Void):
                block()
            case let block as ((Output) -> Void):
                block(output)
            default:
                break
            }
        }
    }
    
    func executeError(with error: RequestError) {
        for block in blocks {
            switch block {
            case let block as (() -> Void):
                block()
            case let block as ((RequestError) -> Void):
                block(error)
            default:
                break
            }
        }
    }
    
    func clearBlocks() {
        // Clear blocks to free up retained objects
        blocks.removeAll()
        cancelBlock = nil
    }
    
    @discardableResult
    public func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self {
        guard !isCancelled, error == nil else {
            return self
        }
        var newBlock: ((Output) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        if !isCancelled, let output = output {
            newBlock(output)
        } else {
            blocks.append(newBlock)
        }
        return self
    }
    
    @discardableResult
    public func `catch`(queue: DispatchQueue?, _ block: @escaping ((RequestError) -> Void)) -> Self {
        guard !isCancelled, output == nil else {
            return self
        }
        var newBlock: ((RequestError) -> Void)
        if let queue = queue {
            newBlock = { error in queue.async { block(error) } }
        } else {
            newBlock = block
        }
        
        if let error = error {
            newBlock(error)
        } else {
            blocks.append(newBlock)
        }
        return self
    }
    
    @discardableResult
    public func always(queue: DispatchQueue? = nil, _ block: @escaping (() -> Void)) -> Self {
        guard !isCancelled else { return self }
        var newBlock: (() -> Void)
        if let queue = queue {
            newBlock = { queue.async { block() } }
        } else {
            newBlock = block
        }
        
        if output != nil || error != nil {
            newBlock()
        } else {
            blocks.append(newBlock)
        }
        return self
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancelBlock?()
        clearBlocks()
    }
    
    func wrap<T>(sinkBlock: @escaping ((Output, Task<T>) -> Void),
                 catchBlock: @escaping ((RequestError, Task<T>) -> Void) = { $1.fail($0) }) -> Task<T> {
        let task = Task<T>()
        sink { sinkBlock($0, task) }
        `catch` { catchBlock($0, task) }
        task.cancelBlock = cancelBlock
        return task
    }
}
