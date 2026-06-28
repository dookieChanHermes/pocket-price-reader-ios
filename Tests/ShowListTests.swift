import XCTest
@testable import PocketPriceReader

/// Exhaustive tests for the show-currency reorder/edit logic (ShowList).
final class ShowListTests: XCTestCase {

    // MARK: add
    func testAdd_appends() { XCTAssertEqual(ShowList.add(["USD"], "EUR"), ["USD", "EUR"]) }
    func testAdd_rejectsDuplicate() { XCTAssertEqual(ShowList.add(["USD", "EUR"], "USD"), ["USD", "EUR"]) }
    func testAdd_rejectsWhenFull() { XCTAssertEqual(ShowList.add(["USD", "EUR", "GBP"], "JPY"), ["USD", "EUR", "GBP"]) }
    func testAdd_rejectsInvalidCode() { XCTAssertEqual(ShowList.add(["USD"], "ZZZ"), ["USD"]) }
    func testAdd_preservesOrder() { XCTAssertEqual(ShowList.add(["GBP", "USD"], "JPY"), ["GBP", "USD", "JPY"]) }

    // MARK: removeAt
    func testRemove_middle() { XCTAssertEqual(ShowList.removeAt(["USD", "EUR", "GBP"], 1), ["USD", "GBP"]) }
    func testRemove_first() { XCTAssertEqual(ShowList.removeAt(["USD", "EUR"], 0), ["EUR"]) }
    func testRemove_keepsAtLeastOne() { XCTAssertEqual(ShowList.removeAt(["USD"], 0), ["USD"]) }
    func testRemove_outOfRange() { XCTAssertEqual(ShowList.removeAt(["USD", "EUR"], 5), ["USD", "EUR"]) }
    func testRemove_negativeIndex() { XCTAssertEqual(ShowList.removeAt(["USD", "EUR"], -1), ["USD", "EUR"]) }

    // MARK: moveUp / moveDown
    func testMoveUp_swapsWithPrev() { XCTAssertEqual(ShowList.moveUp(["USD", "EUR", "GBP"], 2), ["USD", "GBP", "EUR"]) }
    func testMoveUp_toPrimary() { XCTAssertEqual(ShowList.moveUp(["USD", "EUR"], 1), ["EUR", "USD"]) }
    func testMoveUp_atTopIsNoop() { XCTAssertEqual(ShowList.moveUp(["USD", "EUR"], 0), ["USD", "EUR"]) }
    func testMoveUp_outOfRange() { XCTAssertEqual(ShowList.moveUp(["USD", "EUR"], 9), ["USD", "EUR"]) }
    func testMoveDown_swapsWithNext() { XCTAssertEqual(ShowList.moveDown(["USD", "EUR", "GBP"], 0), ["EUR", "USD", "GBP"]) }
    func testMoveDown_atBottomIsNoop() { XCTAssertEqual(ShowList.moveDown(["USD", "EUR"], 1), ["USD", "EUR"]) }
    func testMoveUpDown_roundTrips() {
        let l = ["USD", "EUR", "GBP"]
        XCTAssertEqual(ShowList.moveUp(ShowList.moveDown(l, 0), 1), l)
    }

    // MARK: setAt
    func testSetAt_replaces() { XCTAssertEqual(ShowList.setAt(["USD", "EUR"], 1, "GBP"), ["USD", "GBP"]) }
    func testSetAt_sameIsNoop() { XCTAssertEqual(ShowList.setAt(["USD", "EUR"], 0, "USD"), ["USD", "EUR"]) }
    func testSetAt_duplicateSwaps() { XCTAssertEqual(ShowList.setAt(["USD", "EUR", "GBP"], 0, "GBP"), ["GBP", "EUR", "USD"]) }
    func testSetAt_invalidCodeNoop() { XCTAssertEqual(ShowList.setAt(["USD"], 0, "ZZZ"), ["USD"]) }
    func testSetAt_outOfRangeNoop() { XCTAssertEqual(ShowList.setAt(["USD"], 3, "EUR"), ["USD"]) }

    // MARK: sanitize
    func testSanitize_dropsInvalid() { XCTAssertEqual(ShowList.sanitize(["USD", "ZZZ", "EUR"]), ["USD", "EUR"]) }
    func testSanitize_dedupes() { XCTAssertEqual(ShowList.sanitize(["USD", "USD", "EUR"]), ["USD", "EUR"]) }
    func testSanitize_clampsToThree() { XCTAssertEqual(ShowList.sanitize(["USD", "EUR", "GBP", "JPY"]), ["USD", "EUR", "GBP"]) }
    func testSanitize_emptyDefaultsUsd() { XCTAssertEqual(ShowList.sanitize([]), ["USD"]) }
    func testSanitize_allInvalidDefaultsUsd() { XCTAssertEqual(ShowList.sanitize(["ZZZ", "QQQ"]), ["USD"]) }

    // MARK: serialize / deserialize
    func testSerializeRoundTrip() {
        let l = ["JPY", "USD", "EUR"]
        XCTAssertEqual(ShowList.deserialize(ShowList.serialize(l)), l)
    }
    func testDeserialize_filtersJunk() { XCTAssertEqual(ShowList.deserialize("USD,,ZZZ,EUR"), ["USD", "EUR"]) }
    func testDeserialize_empty() { XCTAssertEqual(ShowList.deserialize(""), ["USD"]) }

    // MARK: realistic reorder scenario
    func testScenario_buildAndReorder() {
        var l = ["USD"]
        l = ShowList.add(l, "EUR")         // [USD, EUR]
        l = ShowList.add(l, "GBP")         // [USD, EUR, GBP]
        l = ShowList.moveUp(l, 2)          // [USD, GBP, EUR]
        l = ShowList.moveUp(l, 1)          // [GBP, USD, EUR]
        XCTAssertEqual(l, ["GBP", "USD", "EUR"])
        l = ShowList.removeAt(l, 1)        // [GBP, EUR]
        XCTAssertEqual(l, ["GBP", "EUR"])
    }
}
