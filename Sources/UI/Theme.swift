import SwiftUI

/// "Petal" kawaii design tokens — a soft sakura-season palette.
enum Tokens {
    static let appBg = hex(0x2B2326)        // camera stage / fallback
    static let panelBg = hex(0xFFF6F2)      // bottom control panel
    static let surface = hex(0xFFFFFF)      // cards / inputs / pill rows
    static let line = Color(red: 217/255, green: 109/255, blue: 143/255).opacity(0.18)
    static let primary = hex(0xD96D8F)      // main cute accent (sakura pink)
    static let primaryDeep = hex(0xA24968)
    static let onPrimary = hex(0xFFFFFF)
    static let textPrimary = hex(0x4A2D36)
    static let textDim = hex(0x8A6470)
    static let textFaint = hex(0xC2A2AC)
    static let overlayText = hex(0xFFFDF7)  // camera-overlay numbers
    static let typeBg = hex(0xFFF0F4)

    static let badge1 = hex(0x7FB7A0)       // mint
    static let badge2 = hex(0xD96D8F)       // pink
    static let badge3 = hex(0xA24968)       // deep pink
    static let tagBg = hex(0xFFD9E4)
    /// Dark halo baked into overlay text so numbers read on ANY camera feed (AAA).
    static let halo = hex(0x2B2A33)

    static func badge(_ index: Int) -> Color {
        switch index { case 0: return badge1; case 1: return badge2; default: return badge3 }
    }

    private static func hex(_ v: UInt) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255,
              green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }
}

extension Font {
    /// Rounded system face (SF Rounded) for the kawaii feel. Use only .regular/.medium.
    static func petal(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Centralised, localised UI copy (warm, playful, short). Each value resolves from
/// Localizable.strings for the active language (en base + ja / zh-Hans / zh-Hant).
enum Copy {
    static var scanMode: String { String(localized: "scan_mode") }
    static var typeMode: String { String(localized: "type_mode") }
    static var hintScan: String { String(localized: "hint_scan") }
    static var permTitle: String { String(localized: "perm_title") }
    static var permBody: String { String(localized: "perm_body") }
    static var permButton: String { String(localized: "perm_button") }
    static var noCamera: String { String(localized: "no_camera") }
    static var todayRateSuffix: String { String(localized: "today_rate_suffix") }
    static var readingLabel: String { String(localized: "reading_label") }
    static var showLabel: String { String(localized: "show_label") }
    static var addCurrency: String { String(localized: "add_currency") }
    static var primaryTag: String { String(localized: "primary_tag") }
    static var doneButton: String { String(localized: "done_button") }
    static var ratesLabel: String { String(localized: "rates_label") }
    static let emptyDash = "—"
}
