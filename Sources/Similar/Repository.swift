//
//  Repository.swift
//  Similar
//
//  Created by Guillermo Cique on 09/02/2020.
//

import Foundation

open class Repository<Output>: Sinkable {
    let request: Request
    weak var dispatcher: Dispatcher!
    public var data: Output? {
        didSet {
            updatedDate = data == nil ? nil : Date()
        }
    }
    public internal(set) var updatedDate: Date?
    var updateTask: Task<Response>?
    var currentTasks: [Task<Output>] = []
    private var transformBlock: ((Data) throws -> Output)
    
    public init(_ path: String, dispatcher: Dispatcher, transformBlock: @escaping ((Data) throws -> Output)) {
        self.request = Request(path)
        self.dispatcher = dispatcher
        self.transformBlock = transformBlock
    }
    
    public init(_ request: Request, dispatcher: Dispatcher, transformBlock: @escaping ((Data) throws -> Output)) {
        self.request = request
        self.dispatcher = dispatcher
        self.transformBlock = transformBlock
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
        task.cancelBlock = { [weak self] in
            self?.currentTasks.removeAll(where: { $0 === task })
        }
        updateIfNecessary()
        return task
    }
    
    func updateIfNecessary() {
        guard updateTask == nil else { return }
        updateTask = dispatcher.execute(request)
            .sink(handleResponse)
            .catch(handleError)
            .always { self.updateTask = nil }
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
    convenience init(_ path: String,
                     decoder: JSONDecoder = Similar.defaultDecoder,
                     dispatcher: Dispatcher) {
        self.init(Request(path), decoder: decoder, dispatcher: dispatcher)
    }
    
    convenience init(_ request: Request,
                     decoder: JSONDecoder = Similar.defaultDecoder,
                     dispatcher: Dispatcher) {
        self.init(request, dispatcher: dispatcher) { data in
            return try decoder.decode(Output.self, from: data)
        }
    }
}

public extension Repository {
    func map<NewOutput>(_ mapBlock: @escaping (Output) -> NewOutput) -> Repository<NewOutput> {
        return Repository<NewOutput>(request, dispatcher: dispatcher) { [transformBlock] data -> NewOutput in
            return mapBlock(try transformBlock(data))
        }
    }
}
