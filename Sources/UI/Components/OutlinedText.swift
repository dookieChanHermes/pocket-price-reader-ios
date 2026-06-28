import SwiftUI

/// Text with a crisp dark outline (8 offset copies of a halo-coloured duplicate) so it
/// stays legible over ANY camera feed — a true contrast guarantee, unlike a soft blur.
struct OutlinedText: View {
    let fill: Text
    let outline: Text
    var radius: CGFloat = 2

    private static let offsets: [(CGFloat, CGFloat)] =
        [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]

    var body: some View {
        ZStack {
            ForEach(0..<Self.offsets.count, id: \.self) { i in
                outline.offset(x: Self.offsets[i].0 * radius, y: Self.offsets[i].1 * radius)
            }
            fill
        }
        .monospacedDigit()
    }
}

extension OutlinedText {
    /// Convenience for single-colour labels.
    static func label(_ string: String, font: Font, color: Color, radius: CGFloat = 1.2,
                      tracking: CGFloat = 0) -> OutlinedText {
        OutlinedText(
            fill: Text(string).font(font).tracking(tracking).foregroundColor(color),
            outline: Text(string).font(font).tracking(tracking).foregroundColor(Tokens.halo),
            radius: radius
        )
    }
}
