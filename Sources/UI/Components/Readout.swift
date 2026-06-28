import SwiftUI

/// The conversion stack (hierarchy layout, §8): primary big (46pt), then up to two more
/// in a compact secondary row (22pt) — bigger fonts without blocking the camera (heavy
/// text shadow, no scrim). Reused by Scan (below the band) and Type modes.
struct Readout: View {
    let conversions: [ShownConversion]

    var body: some View {
        VStack(spacing: 6) {
            if let primary = conversions.first {
                (Text(primary.symbol).font(.system(size: 24, weight: .bold)).foregroundColor(Tokens.amber)
                    + Text(primary.value).font(.system(size: 46, weight: .bold)).foregroundColor(Tokens.paper))
                    .monospacedDigit()
                    .shadow(color: Color.black.opacity(0.9), radius: 7, x: 0, y: 2)
            }

            if conversions.count > 1 {
                HStack(spacing: 18) {
                    ForEach(conversions.dropFirst()) { c in
                        (Text(c.symbol).font(.system(size: 18, weight: .semibold)).foregroundColor(Tokens.amber)
                            + Text(c.value).font(.system(size: 22, weight: .semibold)).foregroundColor(Tokens.paper.opacity(0.85)))
                            .monospacedDigit()
                            .shadow(color: Color.black.opacity(0.9), radius: 6, x: 0, y: 1)
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
    }
}
