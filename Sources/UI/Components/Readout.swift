import SwiftUI

/// The conversion stack (hierarchy, §8): primary big, then up to two more compact.
/// Overlay numbers use a crisp dark outline (OutlinedText) so they stay legible over
/// ANY camera feed (white tags, bright sky, neon signage).
struct Readout: View {
    let conversions: [ShownConversion]

    var body: some View {
        VStack(spacing: 6) {
            if let primary = conversions.first {
                money(primary, value: 44, symbol: 24, radius: 2)
            }
            if conversions.count > 1 {
                HStack(spacing: 18) {
                    ForEach(conversions.dropFirst()) { c in
                        money(c, value: 22, symbol: 18, radius: 1.5)
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
    }

    private func money(_ c: ShownConversion, value: CGFloat, symbol: CGFloat, radius: CGFloat) -> some View {
        OutlinedText(
            fill: Text(c.symbol).font(.petal(symbol, .medium)).foregroundColor(Tokens.primary)
                + Text(c.value).font(.petal(value, .medium)).foregroundColor(Tokens.overlayText),
            outline: (Text(c.symbol).font(.petal(symbol, .medium)) + Text(c.value).font(.petal(value, .medium)))
                .foregroundColor(Tokens.halo),
            radius: radius
        )
    }
}
