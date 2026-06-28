import XCTest
@testable import PocketPriceReader

/// Tests for the rate table: USD base, fallback, and Codable persistence round-trip.
final class RatesTests: XCTestCase {
    func testUsdBaseIsOne() {
        XCTAssertEqual(Rates(map: ["USD": 1, "JPY": 157], whenLabel: "x").rate(of: "USD"), 1)
    }
    func testKnownFromMap() {
        XCTAssertEqual(Rates(map: ["JPY": 157], whenLabel: "x").rate(of: "JPY"), 157)
    }
    func testUnknownFallsBackToBundled() {
        XCTAssertEqual(Rates(map: [:], whenLabel: "x").rate(of: "CNY"), 7.12)
    }
    func testUnknownEverywhereIsNaN() {
        XCTAssertTrue(Rates(map: [:], whenLabel: "x").rate(of: "ZZZ").isNaN)
    }
    func testJsonRoundTripPreservesData() throws {
        let r = Rates(map: ["USD": 1, "JPY": 157, "EUR": 0.92], whenLabel: "Jun 28, 2026")
        let data = try JSONEncoder().encode(r)
        let back = try JSONDecoder().decode(Rates.self, from: data)
        XCTAssertEqual(r, back)
    }
    func testJsonUsesUnderscoreWhenKey() throws {
        let r = Rates(map: ["USD": 1], whenLabel: "stamp")
        let json = String(data: try JSONEncoder().encode(r), encoding: .utf8)!
        XCTAssertTrue(json.contains("_when"))
    }
}
