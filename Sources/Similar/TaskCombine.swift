//
//  TaskCombine.swift
//  Similar
//
//  Created by Guillermo Cique on 18/02/2020.
//

fileprivate extension Task {
    func registerFail(_ tasks: Catchable...) {
        var failed = false
        for task in tasks {
            task.catch { error in
                guard !failed else { return }
                failed = true
                self.fail(error)
            }
        }
    }
    
    func registerCancel(_ tasks: Cancellable...) {
        cancelBlock = {
            tasks.forEach{ $0.cancel() }
        }
    }
}

public extension Similar {
    @discardableResult
    static func combine<O1, O2>(
        _ task1: Task<O1>, _ task2: Task<O2>
    ) -> Task<(O1, O2)> {
        let mainTask = Task<(O1, O2)>()
        let expectedCount = 2
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2) {
            (outputs[1] as! O1, outputs[2] as! O2)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        mainTask.registerFail(task1, task2)
        mainTask.registerCancel(task1, task2)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>
    ) ->Task<(O1, O2, O3)> {
        let mainTask = Task<(O1, O2, O3)>()
        let expectedCount = 3
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        mainTask.registerFail(task1, task2, task3)
        mainTask.registerCancel(task1, task2, task3)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>
    ) ->Task<(O1, O2, O3, O4)> {
        let mainTask = Task<(O1, O2, O3, O4)>()
        let expectedCount = 4
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        mainTask.registerFail(task1, task2, task3, task4)
        mainTask.registerCancel(task1, task2, task3, task4)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>, _ task5: Task<O5>
    ) ->Task<(O1, O2, O3, O4, O5)> {
        let mainTask = Task<(O1, O2, O3, O4, O5)>()
        let expectedCount = 5
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4, outputs[5] as! O5)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        mainTask.registerFail(task1, task2, task3, task4, task5)
        mainTask.registerCancel(task1, task2, task3, task4, task5)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5, O6>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>,
        _ task4: Task<O4>, _ task5: Task<O5>, _ task6: Task<O6>
    ) ->Task<(O1, O2, O3, O4, O5, O6)> {
        let mainTask = Task<(O1, O2, O3, O4, O5, O6)>()
        let expectedCount = 6
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5, O6) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3,
             outputs[4] as! O4, outputs[5] as! O5, outputs[6] as! O6)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        registerSuccess(task6, index: 6)
        mainTask.registerFail(task1, task2, task3, task4, task5, task6)
        mainTask.registerCancel(task1, task2, task3, task4, task5, task6)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5, O6, O7>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>,
        _ task5: Task<O5>, _ task6: Task<O6>, _ task7: Task<O7>
    ) ->Task<(O1, O2, O3, O4, O5, O6, O7)> {
        let mainTask = Task<(O1, O2, O3, O4, O5, O6, O7)>()
        let expectedCount = 7
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5, O6, O7) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4,
             outputs[5] as! O5, outputs[6] as! O6, outputs[7] as! O7)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        registerSuccess(task6, index: 6)
        registerSuccess(task7, index: 7)
        mainTask.registerFail(task1, task2, task3, task4, task5, task6, task7)
        mainTask.registerCancel(task1, task2, task3, task4, task5, task6, task7)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5, O6, O7, O8>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>,
        _ task5: Task<O5>,  _ task6: Task<O6>, _ task7: Task<O7>, _ task8: Task<O8>
    ) ->Task<(O1, O2, O3, O4, O5, O6, O7, O8)> {
        let mainTask = Task<(O1, O2, O3, O4, O5, O6, O7, O8)>()
        let expectedCount = 8
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5, O6, O7, O8) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4,
             outputs[5] as! O5, outputs[6] as! O6, outputs[7] as! O7, outputs[8] as! O8)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        registerSuccess(task6, index: 6)
        registerSuccess(task7, index: 7)
        registerSuccess(task8, index: 8)
        mainTask.registerFail(task1, task2, task3, task4, task5, task6, task7, task8)
        mainTask.registerCancel(task1, task2, task3, task4, task5, task6, task7, task8)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5, O6, O7, O8, O9>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>, _ task5: Task<O5>,
        _ task6: Task<O6>, _ task7: Task<O7>, _ task8: Task<O8>, _ task9: Task<O9>
    ) ->Task<(O1, O2, O3, O4, O5, O6, O7, O8, O9)> {
        let mainTask = Task<(O1, O2, O3, O4, O5, O6, O7, O8, O9)>()
        let expectedCount = 9
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5, O6, O7, O8, O9) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4, outputs[5] as! O5,
             outputs[6] as! O6, outputs[7] as! O7, outputs[8] as! O8, outputs[9] as! O9)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        registerSuccess(task6, index: 6)
        registerSuccess(task7, index: 7)
        registerSuccess(task8, index: 8)
        registerSuccess(task9, index: 9)
        mainTask.registerFail(task1, task2, task3, task4, task5, task6, task7, task8, task9)
        mainTask.registerCancel(task1, task2, task3, task4, task5, task6, task7, task8, task9)
        return mainTask
    }
    
    @discardableResult
    static func combine<O1, O2, O3, O4, O5, O6, O7, O8, O9, O10>(
        _ task1: Task<O1>, _ task2: Task<O2>, _ task3: Task<O3>, _ task4: Task<O4>, _ task5: Task<O5>,
        _ task6: Task<O6>, _ task7: Task<O7>, _ task8: Task<O8>, _ task9: Task<O9>, _ task10: Task<O10>
    ) ->Task<(O1, O2, O3, O4, O5, O6, O7, O8, O9, O10)> {
        let mainTask = Task<(O1, O2, O3, O4, O5, O6, O7, O8, O9, O10)>()
        let expectedCount = 10
        var outputs: [Int: Any] = [:]
        func createTuple() -> (O1, O2, O3, O4, O5, O6, O7, O8, O9, O10) {
            (outputs[1] as! O1, outputs[2] as! O2, outputs[3] as! O3, outputs[4] as! O4, outputs[5] as! O5,
             outputs[6] as! O6, outputs[7] as! O7, outputs[8] as! O8, outputs[9] as! O9, outputs[10] as! O10)
        }
        func registerSuccess<X>(_ task: Task<X>, index: Int) {
            task.sink {
                outputs[index] = $0
                guard outputs.count == expectedCount else { return }
                mainTask.complete(createTuple())
            }
        }
        registerSuccess(task1, index: 1)
        registerSuccess(task2, index: 2)
        registerSuccess(task3, index: 3)
        registerSuccess(task4, index: 4)
        registerSuccess(task5, index: 5)
        registerSuccess(task6, index: 6)
        registerSuccess(task7, index: 7)
        registerSuccess(task8, index: 8)
        registerSuccess(task9, index: 9)
        registerSuccess(task10, index: 10)
        mainTask.registerFail(task1, task2, task3, task4, task5, task6, task7, task8, task9, task10)
        mainTask.registerCancel(task1, task2, task3, task4, task5, task6, task7, task8, task9, task10)
        return mainTask
    }
}
