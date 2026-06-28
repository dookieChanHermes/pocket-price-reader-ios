import Foundation

/// Pure operations on the ordered list of "show" currencies (index 0 = primary, shown
/// biggest). The user can reorder, add (up to 3), remove (keeping >= 1), and change a
/// slot. All ops are total: out-of-range / invalid inputs return the list unchanged.
/// Invariants the ops preserve: 1...maxCount entries, no duplicates, all valid codes.
enum ShowList {
    static let maxCount = 3

    private static func isValid(_ code: String) -> Bool {
        Currencies.all.contains { $0.code == code }
    }

    /// Coerce arbitrary input into a valid list (drop invalids/dups, clamp, default USD).
    static func sanitize(_ list: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for c in list where !c.isEmpty && isValid(c) && !seen.contains(c) {
            seen.insert(c)
            out.append(c)
            if out.count == maxCount { break }
        }
        return out.isEmpty ? ["USD"] : out
    }

    static func add(_ list: [String], _ code: String) -> [String] {
        guard list.count < maxCount, isValid(code), !list.contains(code) else { return list }
        return list + [code]
    }

    static func removeAt(_ list: [String], _ index: Int) -> [String] {
        guard list.count > 1, list.indices.contains(index) else { return list }
        var l = list
        l.remove(at: index)
        return l
    }

    /// Move the entry toward the primary slot (up = earlier).
    static func moveUp(_ list: [String], _ index: Int) -> [String] {
        guard list.indices.contains(index), index > 0 else { return list }
        var l = list
        l.swapAt(index, index - 1)
        return l
    }

    /// Move the entry away from the primary slot (down = later).
    static func moveDown(_ list: [String], _ index: Int) -> [String] {
        guard list.indices.contains(index), index < list.count - 1 else { return list }
        var l = list
        l.swapAt(index, index + 1)
        return l
    }

    /// Set the currency at a slot. Picking one already used elsewhere swaps the two
    /// (keeps the list duplicate-free without dropping an entry).
    static func setAt(_ list: [String], _ index: Int, _ code: String) -> [String] {
        guard list.indices.contains(index), isValid(code) else { return list }
        if list[index] == code { return list }
        var l = list
        if let j = l.firstIndex(of: code) {
            l.swapAt(index, j)
        } else {
            l[index] = code
        }
        return l
    }

    static func serialize(_ list: [String]) -> String { list.joined(separator: ",") }

    static func deserialize(_ s: String) -> [String] {
        // Trim each token (matches Android) so "USD, EUR" parses identically on both.
        sanitize(s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }
}
