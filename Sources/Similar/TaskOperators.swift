//
//  DecodeTask.swift
//  Similar
//
//  Created by Guillermo Cique on 10/02/2020.
//

import Foundation

public extension Task where Output == Response {
    @discardableResult
    func decode<NewOutput: Decodable>(_: NewOutput.Type, decoder: JSONDecoder = Similar.defaultDecoder) -> Task<NewOutput> {
        return wrap(sinkBlock: { (response, task) in
            do {
                let decodedResult = try decoder.decode(NewOutput.self, from: response.data)
                task.complete(decodedResult)
            } catch {
                task.fail(.decodingError(error))
            }
        })
    }
}

public extension Task {
    @discardableResult
    func `catch`<Error: Decodable>(_: Error.Type, decoder: JSONDecoder = Similar.defaultDecoder, _ block: @escaping ((Int, Error) -> Void)) -> Task<Output> {
        return self.catch { error in
            guard case .serverError(let code, let data) = error, let errorData = data,
                let decodedError = try? decoder.decode(Error.self, from: errorData) else {
                return
            }
            block(code, decodedError)
        }
    }
}

public extension Task {
    @discardableResult
    func `guard`(_ guardBlock: @escaping (Output) -> Bool, throw errorBlock: @escaping (Output) -> Error) -> Task<Output> {
        return wrap(sinkBlock: { (data, task) in
            if guardBlock(data) {
                task.complete(data)
            } else {
                let error = errorBlock(data)
                if let error = error as? RequestError {
                    task.fail(error)
                } else {
                    task.fail(.localError(error))
                }
            }
        })
    }

    @discardableResult
    func `guard`(_ guardBlock: @escaping (Output) -> Bool, throw error: Error) -> Task<Output> {
        return `guard`(guardBlock, throw: { _ in error })
    }
}

public extension Task {
    @discardableResult
    func then<NewOutput>(_ taskBlock: @escaping (Output) -> Task<NewOutput>) -> Task<NewOutput> {
        return wrap(sinkBlock: { (data, task) in
            let newTask = taskBlock(data)
                .sink(task.complete)
                .catch(task.fail)
            task.cancelBlock = { [weak newTask] in newTask?.cancel() }
            newTask.progressBlock = { task.progress = $0 }
        })
    }
}

public extension Task {
    @discardableResult
    func print() -> Task<Output> {
        sink { Swift.print(String(describing: $0)) }
        `catch`{ Swift.print(String(describing: $0)) }
        return self
    }
}

public extension Task {
    @discardableResult
    func map<NewOutput>(_ block: @escaping (Output) -> NewOutput) -> Task<NewOutput> {
        return wrap(sinkBlock: { (data, task) in
            let newData = block(data)
            task.complete(newData)
        })
    }
}

public protocol AnyOptional {
    associatedtype Wrapped
    var optional: Optional<Wrapped> { get }
}

extension Optional: AnyOptional {
    public var optional: Optional<Wrapped> { self }
}

public extension Task where Output: AnyOptional {
    func ignoreNil() -> Task<Output.Wrapped> {
        wrap { output, task in
            guard let output = output.optional else {
                task.ignore()
                return
            }
            task.complete(output)
        }
    }
}

public extension Task {
    func eraseType() -> Task<Void> {
        return wrap(sinkBlock: { $1.complete(()) })
    }
}
