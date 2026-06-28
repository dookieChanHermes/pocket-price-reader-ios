import XCTest
@testable import PocketPriceReader

/// Unit tests for parsePrice (spec §7, §11 matrix, AC-5).
final class ParsePriceTests: XCTestCase {

    func testFullWidthDigitsAndComma_AC5() {
        // "￥１，５００" -> 1500
        XCTAssertEqual(parsePrice("￥１，５００"), 1500)
    }

    func testSurroundingText_AC5() {
        // "Aisle 3  ¥980" -> 980 (longest digit run wins)
        XCTAssertEqual(parsePrice("Aisle 3  ¥980"), 980)
    }

    func testNoPrice_AC5() {
        XCTAssertNil(parsePrice("no price"))
    }

    func testThousandsSeparator() {
        XCTAssertEqual(parsePrice("1,500"), 1500)
        XCTAssertEqual(parsePrice("¥12,345"), 12345)
    }

    func testMultipleThousands() {
        XCTAssertEqual(parsePrice("1,234,567"), 1234567)
    }

    func testDecimalComma() {
        XCTAssertEqual(parsePrice("12,5"), 12.5)
    }

    func testDecimalPoint() {
        XCTAssertEqual(parsePrice("$99.99"), 99.99)
    }

    func testMultipleNumbers_longestWins() {
        XCTAssertEqual(parsePrice("2 for 1280 yen"), 1280)
    }

    func testOutOfRange_belowOne() {
        XCTAssertNil(parsePrice("0"))
        XCTAssertNil(parsePrice("0.5"))
    }

    func testOutOfRange_aboveUpperBound() {
        XCTAssertNil(parsePrice("100000000"))
        XCTAssertEqual(parsePrice("99999999"), 99999999)
    }

    func testEmpty() {
        XCTAssertNil(parsePrice(""))
        XCTAssertNil(parsePrice(nil))
    }

    func testFullWidthDecimal() {
        XCTAssertEqual(parsePrice("１２．５"), 12.5)
    }

    /// AC-5 claims parsePrice("03-1234-5678") is nil, but the §7 algorithm (labeled
    /// "exact", matching the reference impl) splits on the hyphens-as-spaces into
    /// 03 / 1234 / 5678 — each in range — so it returns 1234. Documents the actual
    /// behavior and the §7-vs-AC-5 inconsistency. See README "Known spec note".
    func testPhoneNumber_matchesExactAlgorithmNotAC5() {
        XCTAssertEqual(parsePrice("03-1234-5678"), 1234)
    }
}
