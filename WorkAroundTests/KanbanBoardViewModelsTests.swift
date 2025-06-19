import XCTest
@testable import WorkAround   

final class KanbanBoardViewModelTests: XCTestCase {
    
    func testInitFetchesBoardTitle() {
        let viewModel = KanbanBoardViewModel(boardID: "test-board-id")
        
        let expectation = XCTestExpectation(description: "Board title fetched")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotEqual(viewModel.boardTitle, "")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
