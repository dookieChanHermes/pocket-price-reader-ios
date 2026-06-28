import Foundation

/// The three supported foreign currencies (v1).
enum CurrencyCode: String, CaseIterable, Identifiable {
    case JPY, CNY, HKD
    var id: String { rawValue }
}

/// Currency symbols for display (spec theme.ts SYMBOL).
func symbol(of code: String) -> String {
    switch code {
    case "USD": return "$"
    case "JPY": return "¥"
    case "CNY": return "¥"
    case "HKD": return "HK$"
    default: return ""
    }
}

/// Vision recognition languages per currency (FR-14). Numerals parse the same across
/// scripts, but the matching language reads native/full-width digits more reliably.
/// JPY -> japanese, CNY -> chinese, HKD -> latin.
func recognitionLanguages(for cur: CurrencyCode) -> [String] {
    switch cur {
    case .JPY: return ["ja-JP", "en-US"]
    case .CNY: return ["zh-Hans", "en-US"]
    case .HKD: return ["en-US"]
    }
}
