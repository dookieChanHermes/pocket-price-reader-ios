import SwiftUI

/// JPY/CNY/HKD selector (FR-20).
struct CurrencySegment: View {
    @Binding var value: CurrencyCode

    private let items: [(code: CurrencyCode, label: String)] = [
        (.JPY, "¥ JPY"),
        (.CNY, "¥ CNY"),
        (.HKD, "HK$"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.code) { item in
                let on = item.code == value
                Button(action: { value = item.code }) {
                    Text(item.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(on ? Tokens.onAmber : Tokens.paperDim)
                        .frame(maxWidth: .infinity, minHeight: 44) // ≥44pt target (NFR-4)
                        .background(on ? Tokens.amber : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityIdentifier(item.code.rawValue)
            }
        }
        .padding(5)
        .background(Tokens.inkSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
