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
    var alwaysBlock: (() -> Void)?
    private(set) var output: Output? {
        didSet {
            guard oldValue == nil, error == nil, let output = output else {
                preconditionFailure("Invalid output value")
            }
            guard !isCancelled else { return }
            completionBlock?(output)
            alwaysBlock?()
            // Clear blocks to free up retained objects
            completionBlock = nil
            errorBlock = nil
            alwaysBlock = nil
            cancelBlock = nil
        }
    }
    private(set) var completionBlock: ((Output) -> Void)?
    private(set) var error: RequestError? {
        didSet {
            guard output == nil, oldValue == nil, let error = error else {
                preconditionFailure("Invalid error value")
            }
            guard !isCancelled else { return }
            errorBlock?(error)
            alwaysBlock?()
            // Clear blocks to free up retained objects
            completionBlock = nil
            errorBlock = nil
            alwaysBlock = nil
            cancelBlock = nil
        }
    }
    private(set) var errorBlock: ((RequestError) -> Void)?
    
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
    
    @discardableResult
    public func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self {
        var newBlock: ((Output) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        if !isCancelled, let output = output {
            newBlock(output)
        } else {
            let previousCompletionBlock = completionBlock
            completionBlock = {
                previousCompletionBlock?($0)
                newBlock($0)
            }
        }
        return self
    }
    
    @discardableResult
    public func `catch`(queue: DispatchQueue?, _ block: @escaping ((RequestError) -> Void)) -> Self {
        var newBlock: ((RequestError) -> Void)
        if let queue = queue {
            newBlock = { error in queue.async { block(error) } }
        } else {
            newBlock = block
        }
        
        if !isCancelled, let error = error {
            newBlock(error)
        } else {
            let previousErrorBlock = errorBlock
            errorBlock = {
                previousErrorBlock?($0)
                newBlock($0)
            }
        }
        return self
    }
    
    @discardableResult
    public func always(queue: DispatchQueue? = nil, _ block: @escaping (() -> Void)) -> Self {
        var newBlock: (() -> Void)
        if let queue = queue {
            newBlock = { queue.async { block() } }
        } else {
            newBlock = block
        }
        
        if !isCancelled, output != nil || error != nil {
            newBlock()
        } else {
            let previousAlwaysBlock = alwaysBlock
            alwaysBlock = {
                previousAlwaysBlock?()
                newBlock()
            }
        }
        return self
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancelBlock?()
        cancelBlock = nil
    }
    
    func wrap<T>(sinkBlock: @escaping ((Output, Task<T>) -> Void),
                 catchBlock: @escaping ((RequestError, Task<T>) -> Void) = { $1.fail($0) }) -> Task<T> {
        let task = Task<T>()
        sink { sinkBlock($0, task) }
        `catch` { catchBlock($0, task) }
        task.cancelBlock = cancel
        return task
    }
}
