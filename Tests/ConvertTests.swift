import XCTest
@testable import PocketPriceReader

/// Unit tests for convert (spec §7, AC-1) — cross-rate model. Pinned to the bundled
/// fallback map so tests don't depend on the host app's live fetch.
final class ConvertTests: XCTestCase {
    private let acc = 1e-9

    @MainActor
    override func setUp() {
        super.setUp()
        RatesStore.shared._setForTesting(RatesStore._bundledFallback)
    }

    func testReadToUsd_jpy_AC1() {
        // 1500 JPY at 157.0 -> ~9.55 USD
        XCTAssertEqual(convert(1500, from: "JPY", to: "USD"), 1500.0 / 157.0, accuracy: acc)
    }

    func testUsdToRead_jpy() {
        XCTAssertEqual(convert(10, from: "USD", to: "JPY"), 10.0 * 157.0, accuracy: acc)
    }

    func testCrossRate_jpyToCny() {
        // 1000 JPY -> USD -> CNY
        XCTAssertEqual(convert(1000, from: "JPY", to: "CNY"), 1000.0 / 157.0 * 7.12, accuracy: acc)
    }

    func testIdentity() {
        XCTAssertEqual(convert(500, from: "HKD", to: "HKD"), 500, accuracy: acc)
    }

    func testShownConversions_skipsNoneAndOrders() {
        let result = shownConversions(amount: 1500, from: "JPY", showCodes: ["USD", "", "EUR"])
        XCTAssertEqual(result.map { $0.code }, ["USD", "EUR"]) // empty slot skipped, order kept
        XCTAssertEqual(result.first?.symbol, "$")
        XCTAssertEqual(result.last?.symbol, "€")
    }

    func testShownConversions_primaryOnly() {
        let result = shownConversions(amount: 1500, from: "JPY", showCodes: ["USD", "", ""])
        XCTAssertEqual(result.count, 1)
    }
}
