import SwiftUI

/// Camera overlay (FR-15, §8). Line 1 = detected price in input currency (dim).
/// Line 2 = converted value, 46pt bold, symbol in amber, heavy shadow for legibility
/// over arbitrary feeds (NFR-4). Shown only when there is a detection (FR-16).
struct Readout: View {
    let detectedLabel: String
    let outSymbol: String
    let outValue: String

    var body: some View {
        VStack(spacing: 2) {
            Text(detectedLabel)
                .font(.system(size: 15))
                .tracking(0.5)
                .foregroundColor(Tokens.paperDim)
                .monospacedDigit()

            (Text(outSymbol).font(.system(size: 24, weight: .bold)).foregroundColor(Tokens.amber)
                + Text(outValue).font(.system(size: 46, weight: .bold)).foregroundColor(Tokens.paper))
                .monospacedDigit()
                .shadow(color: Color.black.opacity(0.9), radius: 7, x: 0, y: 2)
        }
        .multilineTextAlignment(.center)
    }
}
