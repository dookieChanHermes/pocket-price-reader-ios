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

/// Centralised UI copy (warm, playful, short).
enum Copy {
    static let scanMode = "🌸 Scan a tag"
    static let typeMode = "Type it"
    static let hintScan = "Point at a price tag and hold steady"
    static let permTitle = "Let Petal peek through the camera"
    static let permBody = "Petal reads price tags live and converts them on the spot. Nothing is saved or sent anywhere."
    static let permButton = "Turn on camera"
    static let noCamera = "No camera here, so let’s type the price instead."
    static let todayRateSuffix = "at today’s rate"
    static let readingLabel = "Reading"
    static let showLabel = "Show in"
    static let addCurrency = "Add a currency"
    static let emptyDash = "—"
}
