import Foundation

/// A supported currency: ISO code, display symbol, human name.
struct Currency: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }
}

/// Curated travel currency list. The rate API (USD-based) covers all of these,
/// so any can be a "show" currency; conversion is a cross-rate.
enum Currencies {
    static let all: [Currency] = [
        Currency(code: "USD", symbol: "$",    name: "US Dollar"),
        Currency(code: "EUR", symbol: "€",    name: "Euro"),
        Currency(code: "GBP", symbol: "£",    name: "British Pound"),
        Currency(code: "JPY", symbol: "¥",    name: "Japanese Yen"),
        Currency(code: "CNY", symbol: "¥",    name: "Chinese Yuan"),
        Currency(code: "HKD", symbol: "HK$",  name: "Hong Kong Dollar"),
        Currency(code: "KRW", symbol: "₩",    name: "Korean Won"),
        Currency(code: "TWD", symbol: "NT$",  name: "Taiwan Dollar"),
        Currency(code: "SGD", symbol: "S$",   name: "Singapore Dollar"),
        Currency(code: "THB", symbol: "฿",    name: "Thai Baht"),
        Currency(code: "AUD", symbol: "A$",   name: "Australian Dollar"),
        Currency(code: "CAD", symbol: "C$",   name: "Canadian Dollar"),
        Currency(code: "CHF", symbol: "Fr",   name: "Swiss Franc"),
        Currency(code: "NZD", symbol: "NZ$",  name: "New Zealand Dollar"),
        Currency(code: "MYR", symbol: "RM",   name: "Malaysian Ringgit"),
        Currency(code: "VND", symbol: "₫",    name: "Vietnamese Dong"),
        Currency(code: "INR", symbol: "₹",    name: "Indian Rupee"),
        Currency(code: "IDR", symbol: "Rp",   name: "Indonesian Rupiah"),
        Currency(code: "PHP", symbol: "₱",    name: "Philippine Peso"),
        Currency(code: "MXN", symbol: "Mex$", name: "Mexican Peso"),
    ]

    static func symbol(_ code: String) -> String {
        all.first { $0.code == code }?.symbol ?? code
    }
    static func name(_ code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }

    /// Localised currency name for the active language (system-provided), with the
    /// bundled English name as a fallback. e.g. USD → "米ドル" (ja) / "美元" (zh).
    static func displayName(_ code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? name(code)
    }

    /// Flag emoji for a cute touch in the picker / show-list.
    static func flag(_ code: String) -> String {
        switch code {
        case "USD": return "🇺🇸"; case "EUR": return "🇪🇺"; case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"; case "CNY": return "🇨🇳"; case "HKD": return "🇭🇰"
        case "KRW": return "🇰🇷"; case "TWD": return "🇹🇼"; case "SGD": return "🇸🇬"
        case "THB": return "🇹🇭"; case "AUD": return "🇦🇺"; case "CAD": return "🇨🇦"
        case "CHF": return "🇨🇭"; case "NZD": return "🇳🇿"; case "MYR": return "🇲🇾"
        case "VND": return "🇻🇳"; case "INR": return "🇮🇳"; case "IDR": return "🇮🇩"
        case "PHP": return "🇵🇭"; case "MXN": return "🇲🇽"; default: return "🏳️"
        }
    }
}

/// OCR script per read currency (FR-14): JPY→japanese, CNY→chinese, else latin.
enum OcrScript { case japanese, chinese, latin }

func ocrScript(forRead code: String) -> OcrScript {
    switch code {
    case "JPY": return .japanese
    case "CNY": return .chinese
    default: return .latin
    }
}

/// Vision recognition languages for a read currency (FR-14).
func recognitionLanguages(forRead code: String) -> [String] {
    switch code {
    case "JPY": return ["ja-JP", "en-US"]
    case "CNY": return ["zh-Hans", "en-US"]
    default: return ["en-US"]
    }
}
