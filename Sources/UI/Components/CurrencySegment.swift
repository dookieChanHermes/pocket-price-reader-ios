import SwiftUI

/// Read-currency selector (the currency on the tag; drives OCR). 3 options (FR-14, FR-20).
struct ReadSegment: View {
    @Binding var value: String

    private func label(_ code: String) -> String {
        "\(Currencies.flag(code)) \(code)"
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Currencies.readCodes, id: \.self) { code in
                let on = code == value
                Button(action: { value = code }) {
                    Text(label(code))
                        .font(.petal(15, .medium))
                        .foregroundColor(on ? Tokens.onPrimary : Tokens.textDim)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(on ? Tokens.primary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityIdentifier("read-\(code)")
            }
        }
        .padding(5)
        .background(Tokens.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tokens.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
