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

    /// Broad corpus (kept identical to the Android ParsePriceTest corpus so both
    /// platforms behave the same). Native uses strict Double parsing, so multi-dot
    /// tokens like "12.34.56" yield nil (documented divergence from the JS reference).
    func testCorpus() {
        let cases: [(String?, Double?)] = [
            ("¥1,500", 1500), ("￥１，５００", 1500), ("1,234,567", 1234567),
            ("12,5", 12.5), ("12,50", 12.5), ("1,500.00", 1500), ("$99.99", 99.99),
            ("Aisle 3  ¥980", 980), ("Total 3980 yen", 3980), ("Buy 2 get 1 ¥2980", 2980),
            ("no price", nil), ("", nil), ("0", nil), ("0.99", nil), ("1", 1),
            ("99999999", 99999999), ("100000000", nil), ("1980円", 1980), ("１２．５", 12.5),
            ("￥０", nil), ("100 200", 100), ("3.5", 3.5), ("1000000", 1000000),
            ("12.34.56", nil), ("abc", nil), ("   ", nil), ("¥1,980 税込", 1980),
            ("50% off 1280", 1280), ("1,2,3", nil), ("1.5 1500", 1500), ("元 7,12", 7.12),
        ]
        for (i, (input, expected)) in cases.enumerated() {
            XCTAssertEqual(parsePrice(input), expected, "case \(i): \(String(describing: input))")
        }
    }
}
