//
//  Repository.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

open class Repository<Output>: Sinkable {
    let taskBuilder: (() -> Task<Response>?)
    public var data: Output? {
        didSet {
            updatedDate = data == nil ? nil : Date()
        }
    }
    public internal(set) var updatedDate: Date?
    var updateTask: Task<Response>?
    var currentTasks: [Task<Output>] = []
    private var transformBlock: ((Data) throws -> Output)
    
    public init(taskBuilder: @escaping (() -> Task<Response>?), transformBlock: @escaping ((Data) throws -> Output)) {
        self.taskBuilder = taskBuilder
        self.transformBlock = transformBlock
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    public func fetch(forceUpdate: Bool = false) -> Task<Output> {
        if forceUpdate {
            data = nil
        }
        // Check if data is ready, check expiration?
        if let data = data {
            return Task(output: data)
        }
        // Save tasks
        let task = Task<Output>()
        currentTasks.append(task)
        task.cancelBlock = { [weak self, weak task] in
            self?.currentTasks.removeAll(where: { $0 === task })
        }
        updateIfNecessary()
        return task
    }
    
    func updateIfNecessary() {
        guard updateTask == nil else { return }
        guard let task = taskBuilder() else {
            Swift.print("Task not available, will not update")
            return
        }
        updateTask = task
            .sink { [weak self] in self?.handleResponse($0) }
            .catch { [weak self] in self?.handleError($0) }
            .always { [weak self] in self?.updateTask = nil }
    }
    
    func handleResponse(_ response: Response) {
        do {
            let parsedData = try transformBlock(response.data)
            self.data = parsedData
            let currentTasks = self.currentTasks
            self.currentTasks.removeAll()
            currentTasks.forEach { $0.complete(parsedData) }
        } catch {
            handleError(.decodingError(error))
        }
    }
    
    func handleError(_ error: RequestError) {
        let currentTasks = self.currentTasks
        self.currentTasks.removeAll()
        currentTasks.forEach { $0.fail(error) }
    }
    
    @discardableResult
    public func sink(queue: DispatchQueue?, _ block: @escaping ((Output) -> Void)) -> Self {
        let previousTransformBlock = transformBlock
        var newBlock: ((Output) -> Void)
        if let queue = queue {
            newBlock = { output in queue.async { block(output) } }
        } else {
            newBlock = block
        }
        transformBlock = { data in
            let output = try previousTransformBlock(data)
            newBlock(output)
            return output
        }
        return self
    }
}

public extension Repository where Output: Decodable {
    convenience init(taskBuilder: @escaping (() -> Task<Response>?), decoder: JSONDecoder = Similar.defaultDecoder) {
        self.init(taskBuilder: taskBuilder) { data in
            return try decoder.decode(Output.self, from: data)
        }
    }
    
    convenience init(_ path: String, decoder: JSONDecoder = Similar.defaultDecoder, dispatcher: Dispatcher) {
        self.init(Request(path), decoder: decoder, dispatcher: dispatcher)
    }
    
    convenience init(_ request: Request, decoder: JSONDecoder = Similar.defaultDecoder, dispatcher: Dispatcher) {
        self.init(request, dispatcher: dispatcher) { data in
            return try decoder.decode(Output.self, from: data)
        }
    }
}

public extension Repository {
    convenience init(_ request: Request, dispatcher: Dispatcher, transformBlock: @escaping ((Data) throws -> Output)) {
        self.init(taskBuilder: { [weak dispatcher] in
            guard let dispatcher = dispatcher else { return nil }
            return dispatcher.execute(request)
        }, transformBlock: transformBlock)
    }
    
    convenience init(_ path: String, dispatcher: Dispatcher, transformBlock: @escaping ((Data) throws -> Output)) {
        self.init(Request(path), dispatcher: dispatcher, transformBlock: transformBlock)
    }
    
    func map<NewOutput>(_ mapBlock: @escaping (Output) -> NewOutput) -> Repository<NewOutput> {
        return Repository<NewOutput>(taskBuilder: taskBuilder) { [transformBlock] data -> NewOutput in
            return mapBlock(try transformBlock(data))
        }
    }
}
