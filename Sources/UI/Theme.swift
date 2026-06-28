import SwiftUI

/// Design tokens (spec §8).
enum Tokens {
    static let ink = Color(red: 0x0f / 255, green: 0x11 / 255, blue: 0x15 / 255)
    static let inkSoft = Color(red: 0x1a / 255, green: 0x1e / 255, blue: 0x26 / 255)
    static let amber = Color(red: 0xf4 / 255, green: 0xb9 / 255, blue: 0x42 / 255)
    static let amberDeep = Color(red: 0xc8 / 255, green: 0x86 / 255, blue: 0x1f / 255)
    static let paper = Color(red: 0xf7 / 255, green: 0xf4 / 255, blue: 0xec / 255)
    static let paperDim = Color(red: 0xf7 / 255, green: 0xf4 / 255, blue: 0xec / 255).opacity(0.6)
    static let paperFaint = Color(red: 0xf7 / 255, green: 0xf4 / 255, blue: 0xec / 255).opacity(0.4)
    static let good = Color(red: 0x6f / 255, green: 0xcf / 255, blue: 0x97 / 255)
    static let line = Color.white.opacity(0.10)
    static let onAmber = Color(red: 0x1a / 255, green: 0x12 / 255, blue: 0x05 / 255)
    static let stage = Color(red: 0x0a / 255, green: 0x0a / 255, blue: 0x0a / 255)
}
