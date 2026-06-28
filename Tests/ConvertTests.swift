import XCTest
@testable import PocketPriceReader

/// Unit tests for convert (spec §7, AC-1, AC-2). Runs against the bundled fallback
/// rates (JPY 157.0, CNY 7.12, HKD 7.8) — RatesStore defaults to these with no
/// network, so these tests are deterministic.
final class ConvertTests: XCTestCase {
    private let acc = 1e-9

    @MainActor
    override func setUp() {
        super.setUp()
        // Pin to the bundled fallback so tests don't depend on the host app's live fetch.
        RatesStore.shared._setForTesting(RatesStore._bundledFallback)
    }

    func testForeignToUsd_jpy_AC1() {
        // 1500 JPY at 157.0 -> ~9.55 USD
        XCTAssertEqual(convert(1500, .JPY, foreignToUsd: true), 1500.0 / 157.0, accuracy: acc)
    }

    func testUsdToForeign_jpy() {
        XCTAssertEqual(convert(10, .JPY, foreignToUsd: false), 10.0 * 157.0, accuracy: acc)
    }

    func testBothDirections_cny() {
        XCTAssertEqual(convert(100, .CNY, foreignToUsd: true), 100.0 / 7.12, accuracy: acc)
        XCTAssertEqual(convert(100, .CNY, foreignToUsd: false), 100.0 * 7.12, accuracy: acc)
    }

    func testBothDirections_hkd() {
        XCTAssertEqual(convert(100, .HKD, foreignToUsd: true), 100.0 / 7.8, accuracy: acc)
        XCTAssertEqual(convert(100, .HKD, foreignToUsd: false), 100.0 * 7.8, accuracy: acc)
    }

    func testDirectionLabels_AC2() {
        XCTAssertEqual(inCurrency(.JPY, foreignToUsd: true), "JPY")
        XCTAssertEqual(outCurrency(.JPY, foreignToUsd: true), "USD")
        XCTAssertEqual(inCurrency(.JPY, foreignToUsd: false), "USD")
        XCTAssertEqual(outCurrency(.JPY, foreignToUsd: false), "JPY")
    }
}
