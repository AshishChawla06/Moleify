import XCTest
@testable import Moleify

final class MoleifyTests: XCTestCase {
    func testDataModels() {
        let stats = SystemStats()
        XCTAssertEqual(stats.cpuUsage, 0.0)
    }
}
