import Foundation

/// Turn raw OCR text into the single most plausible price number.
/// Faithful port of spec §7 "Algorithm (exact)":
///
///  1. Normalize full-width digits U+FF10–U+FF19 -> ASCII; U+FF0C -> ','; U+FF0E -> '.'.
///  2. Replace every char not in [0-9.,\s] with a space; trim.
///  3. Split on whitespace. Per token: strip thousands commas (',' before exactly 3
///     digits at a word boundary), then convert any remaining ',' to '.'.
///  4. parse Double; keep if 1 <= n < 100_000_000.
///  5. Among kept values, return the one whose token string is longest. Ties: first.
///  6. No candidates -> nil.
func parsePrice(_ raw: String?) -> Double? {
    guard let raw, !raw.isEmpty else { return nil }

    let normalized = normalizeDigits(raw)
    // Replace any char not in [0-9.,whitespace] with a space.
    let scalars = normalized.unicodeScalars.map { s -> Character in
        if (s >= "0" && s <= "9") || s == "." || s == "," || CharacterSet.whitespaces.contains(s) {
            return Character(s)
        }
        return " "
    }
    let cleaned = String(scalars).trimmingCharacters(in: .whitespaces)
    if cleaned.isEmpty { return nil }

    var best: Double? = nil
    var bestLen = -1
    for rawToken in cleaned.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }) {
        let token = stripThousands(String(rawToken)).replacingOccurrences(of: ",", with: ".")
        guard let n = Double(token) else { continue }
        if n >= 1 && n < 100_000_000 {
            // prefer the longest token — usually the real price, not a "2" for aisle 2
            if token.count > bestLen {
                best = n
                bestLen = token.count
            }
        }
    }
    return best
}

private func normalizeDigits(_ s: String) -> String {
    var out = String.UnicodeScalarView()
    for scalar in s.unicodeScalars {
        switch scalar.value {
        case 0xFF10...0xFF19: // full-width 0-9 -> ASCII
            out.append(Unicode.Scalar(scalar.value - 0xFEE0)!)
        case 0xFF0C: // full-width comma
            out.append(",")
        case 0xFF0E: // full-width period
            out.append(".")
        default:
            out.append(scalar)
        }
    }
    return String(out)
}

/// Strip a comma that is immediately followed by exactly three digits ending a run
/// (e.g. "1,500" -> "1500"), matching the JS regex /,(?=\d{3}\b)/g.
private func stripThousands(_ token: String) -> String {
    let chars = Array(token)
    var result = [Character]()
    var i = 0
    while i < chars.count {
        if chars[i] == "," {
            // look ahead: exactly 3 digits, then a non-digit (or end of string).
            let d1 = i + 1 < chars.count && chars[i + 1].isNumber
            let d2 = i + 2 < chars.count && chars[i + 2].isNumber
            let d3 = i + 3 < chars.count && chars[i + 3].isNumber
            let boundary = (i + 4 >= chars.count) || !chars[i + 4].isNumber
            if d1 && d2 && d3 && boundary {
                // drop the comma
                i += 1
                continue
            }
        }
        result.append(chars[i])
        i += 1
    }
    return String(result)
}
