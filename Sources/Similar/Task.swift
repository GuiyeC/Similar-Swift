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

public enum TaskState {
    case alive
    case completed
    case failed
    case ignored
    case cancelled
}

public class Task<Output>: Sinkable, Catchable, Cancellable {
    public private(set) var state: TaskState = .alive
    private(set) var output: Output?
    private(set) var error: RequestError?
    public var progress: Double? {
        didSet { progress.map { progressBlock?($0) } }
    }
    var blocks: [Any] = []
    var progressBlock: ((Double) -> Void)?
    public var cancelBlock: (() -> Void)?
    
    public init() {}
    
    public init(output: Output) {
        complete(output)
    }
    
    public init(error: RequestError) {
        fail(error)
    }
    
    public func complete(_ output: Output) {
        guard state != .cancelled else { return }
        guard state == .alive else { preconditionFailure("Invalid state: \(state)") }
        self.output = output
        self.state = .completed
        executeCompletion(with: output)
        clearBlocks()
    }
    
    func ignore() {
        guard state != .cancelled else { return }
        guard state == .alive else { preconditionFailure("Invalid state: \(state)") }
        self.state = .ignored
        clearBlocks()
    }
    
    public func fail(_ error: RequestError) {
        guard state != .cancelled else { return }
        guard state == .alive else { preconditionFailure("Invalid state: \(state)") }
        self.error = error
        self.state = .failed
        executeError(with: error)
        clearBlocks()
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
        progressBlock = nil
        cancelBlock = nil
    }
    
    @discardableResult
    public func progress(queue: DispatchQueue? = nil, _ block: @escaping ((Double) -> Void)) -> Self {
        guard state == .alive else {
            return self
        }
        var newBlock: ((Double) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        if let previousBlock = progressBlock {
            progressBlock = {
                previousBlock($0)
                newBlock($0)
            }
        } else {
            progressBlock = newBlock
        }
        return self
    }
    
    @discardableResult
    public func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self {
        guard state == .alive || state == .completed else {
            return self
        }
        var newBlock: ((Output) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        if let output = output {
            newBlock(output)
        } else {
            blocks.append(newBlock)
        }
        return self
    }
    
    @discardableResult
    public func `catch`(queue: DispatchQueue?, _ block: @escaping ((RequestError) -> Void)) -> Self {
        guard state == .alive || state == .failed else {
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
        guard state != .cancelled else { return self }
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
        guard state != .alive else {
            Swift.print("Task could not be cancelled, task state: \(state)")
            return
        }
        state = .cancelled
        cancelBlock?()
        clearBlocks()
    }
    
    func wrap<T>(sinkBlock: @escaping ((Output, Task<T>) -> Void),
                 catchBlock: @escaping ((RequestError, Task<T>) -> Void) = { $1.fail($0) }) -> Task<T> {
        let task = Task<T>()
        sink { sinkBlock($0, task) }
        `catch` { catchBlock($0, task) }
        task.cancelBlock = cancelBlock
        task.progressBlock = progressBlock
        progressBlock = { task.progress = $0 }
        return task
    }
}
