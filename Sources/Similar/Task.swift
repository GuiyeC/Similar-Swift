//
//  Task.swift
//  Similar
//
//  Created by Guillermo Cique on 08/02/2020.
//

import Foundation

public protocol Sinkable {
    associatedtype Output
    func sink(_ block: @escaping ((Output) -> Void)) -> Self
}

public protocol Catchable {
    @discardableResult
    func `catch`(_ block: @escaping ((RequestError) -> Void)) -> Self
}

public protocol Cancellable {
    func cancel()
}

public class Task<Output>: Sinkable, Catchable, Cancellable {
    public private(set) var isCancelled: Bool = false
    var cancelBlock: (() -> Void)?
    var alwaysBlock: (() -> Void)? {
        didSet {
            guard !isCancelled, output != nil || error != nil else { return }
            alwaysBlock?()
        }
    }
    private(set) var output: Output? {
        didSet {
            guard oldValue == nil, error == nil, let output = output else {
                preconditionFailure("Invalid output value")
            }
            guard !isCancelled else { return }
            completionBlock?(output)
            alwaysBlock?()
        }
    }
    private(set) var completionBlock: ((Output) -> Void)? {
        didSet {
            guard !isCancelled, let output = output else { return }
            completionBlock?(output)
        }
    }
    private(set) var error: RequestError? {
        didSet {
            guard output == nil, oldValue == nil, let error = error else {
                preconditionFailure("Invalid error value")
            }
            guard !isCancelled else { return }
            errorBlock?(error)
            alwaysBlock?()
        }
    }
    private(set) var errorBlock: ((RequestError) -> Void)? {
        didSet {
            guard !isCancelled, let error = error else { return }
            errorBlock?(error)
        }
    }
    
    init() {}
    
    init(output: Output) {
        complete(output)
    }
    
    init(error: RequestError) {
        fail(error)
    }
    
    func complete(_ output: Output) {
        self.output = output
    }
    
    func fail(_ error: RequestError) {
        self.error = error
    }
    
    @discardableResult
    public func sink(_ block: @escaping ((Output) -> Void)) -> Self { self.sink(queue: nil, block) }
    
    @discardableResult
    public func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self {
        let previousCompletionBlock = completionBlock
        var newBlock: ((Output) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        completionBlock = {
            previousCompletionBlock?($0)
            newBlock($0)
        }
        return self
    }
    
    @discardableResult
    public func `catch`(_ block: @escaping ((RequestError) -> Void)) -> Self { self.catch(queue: nil, block) }
    
    @discardableResult
    public func `catch`(queue: DispatchQueue?, _ block: @escaping ((RequestError) -> Void)) -> Self {
        let previousErrorBlock = errorBlock
        var newBlock: ((RequestError) -> Void)
        if let queue = queue {
            newBlock = { error in queue.async { block(error) } }
        } else {
            newBlock = block
        }
        errorBlock = {
            previousErrorBlock?($0)
            newBlock($0)
        }
        return self
    }
    
    @discardableResult
    public func always(queue: DispatchQueue? = nil, _ block: @escaping (() -> Void)) -> Self {
        let previousAlwaysBlock = alwaysBlock
        var newBlock: (() -> Void)
        if let queue = queue {
            newBlock = { queue.async { block() } }
        } else {
            newBlock = block
        }
        alwaysBlock = {
            previousAlwaysBlock?()
            newBlock()
        }
        return self
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancelBlock?()
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
