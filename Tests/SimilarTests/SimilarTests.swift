import XCTest
@testable import Similar

final class SimilarTests: XCTestCase {

    static var allTests = [
        ("testClearingBlocksOnCompletedTasks", testClearingBlocksOnCompletedTasks),
        ("testClearingBlocksOnIgnoreNil", testClearingBlocksOnIgnoreNil),
        ("testBlockOrder", testBlockOrder),
        ("testBlockOrder", testProgress),
    ]
    
    func testClearingBlocksOnCompletedTasks() {
        let task = Task<String>()
        task.complete("2")
        let mapTask = task.map { _ in 2 }
        
        XCTAssert(task.blocks.isEmpty)
        XCTAssertNil(task.cancelBlock)
        XCTAssert(mapTask.blocks.isEmpty)
        XCTAssertNil(mapTask.cancelBlock)
    }
    
    func testClearingBlocksOnIgnoreNil() {
        let task = Task<String?>()
        let notNilTask = task.ignoreNil()
        task.complete(nil)
        let mapTask = notNilTask.map { _ in 2 }
        
        XCTAssert(task.blocks.isEmpty)
        XCTAssertNil(task.cancelBlock)
        XCTAssert(notNilTask.blocks.isEmpty)
        XCTAssertNil(notNilTask.cancelBlock)
        XCTAssert(mapTask.blocks.isEmpty)
        XCTAssertNil(mapTask.cancelBlock)
    }
    
    func testBlockOrder() {
        var _order: Int = 0
        var order: Int {
            let order = _order
            _order += 1
            return order
        }
        let task = Task<Void>()
            .sink { XCTAssert(order == 0) }
            .always { XCTAssert(order == 1) }
            .sink { XCTAssert(order == 2) }
            .always { XCTAssert(order == 3) }
        task.complete(())
    }
    
    let dispatcher = NetworkDispatcher()
    func testProgress() {
        let progressExpectation = expectation(description: "Task progress")
        let sinkExpectation = expectation(description: "Task completed")
        let request = Request("http://ipv4.download.thinkbroadband.com/20MB.zip")
        dispatcher.execute(request)
            .eraseType()
            .progress { progress in
                if progress == 1 {
                    progressExpectation.fulfill()
                }
            }
            .sink { sinkExpectation.fulfill() }
        waitForExpectations(timeout: 10)
        XCTAssert(dispatcher.progressTokens.isEmpty)
    }
}
