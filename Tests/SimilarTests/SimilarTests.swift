import XCTest
@testable import Similar

final class SimilarTests: XCTestCase {

    static var allTests = [
        ("testClearingBlocksOnCompletedTasks", testClearingBlocksOnCompletedTasks),
        ("testBlockOrder", testBlockOrder),
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
}
