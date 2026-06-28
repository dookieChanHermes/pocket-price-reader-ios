import SwiftUI

/// Read-currency selector (the currency on the tag; drives OCR). 3 options (FR-14, FR-20).
struct ReadSegment: View {
    @Binding var value: String

    private func label(_ code: String) -> String {
        switch code {
        case "JPY": return "¥ JPY"
        case "CNY": return "¥ CNY"
        case "HKD": return "HK$"
        default: return code
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Currencies.readCodes, id: \.self) { code in
                let on = code == value
                Button(action: { value = code }) {
                    Text(label(code))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(on ? Tokens.onAmber : Tokens.paperDim)
                        .frame(maxWidth: .infinity, minHeight: 44) // ≥44pt target (NFR-4)
                        .background(on ? Tokens.amber : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityIdentifier("read-\(code)")
            }
        }
        .padding(5)
        .background(Tokens.inkSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
