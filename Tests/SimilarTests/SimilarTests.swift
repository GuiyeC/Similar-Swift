import XCTest
@testable import Similar

final class SimilarTests: XCTestCase {

    static var allTests = [
        ("testExample", testExample),
        ("testClearingBlocksOnCompletedTasks", testClearingBlocksOnCompletedTasks),
    ]
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
    }
    
    func testClearingBlocksOnCompletedTasks() {
        let task = Task<String>()
        task.complete("2")
        let mapTask = task.map { _ in 2 }
        
        XCTAssertNil(task.completionBlock)
        XCTAssertNil(task.errorBlock)
        XCTAssertNil(task.alwaysBlock)
        XCTAssertNil(task.cancelBlock)
        XCTAssertNil(mapTask.completionBlock)
        XCTAssertNil(mapTask.errorBlock)
        XCTAssertNil(mapTask.alwaysBlock)
        XCTAssertNil(mapTask.cancelBlock)
    }
}
