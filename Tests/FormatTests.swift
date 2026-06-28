import XCTest
@testable import PocketPriceReader

/// Tests for edge-formatting (grouping + rounding).
final class FormatTests: XCTestCase {
    func testMoney_groupsThousands() { XCTAssertEqual(formatMoney(1500), "1,500") }
    func testMoney_roundsToTwo() { XCTAssertEqual(formatMoney(9.27594), "9.28") }
    func testMoney_keepsHalf() { XCTAssertEqual(formatMoney(0.5), "0.5") }
    func testMoney_bigWithDecimals() { XCTAssertEqual(formatMoney(1234567.891), "1,234,567.89") }
    func testMoney_millionNoDecimals() { XCTAssertEqual(formatMoney(1000000), "1,000,000") }
    func testMoney_zero() { XCTAssertEqual(formatMoney(0), "0") }

    func testGrouped_integer() { XCTAssertEqual(formatGrouped(1500), "1,500") }
    func testGrouped_oneDecimal() { XCTAssertEqual(formatGrouped(1500.5), "1,500.5") }
    func testGrouped_threeDecimals() { XCTAssertEqual(formatGrouped(1234.567), "1,234.567") }
}
