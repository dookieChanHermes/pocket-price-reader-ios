import SwiftUI

/// Read-currency picker (the currency on the tag; drives OCR). Any currency is allowed —
/// JPY uses the Japanese recognizer, CNY the Chinese one, everything else Latin (which
/// reads the Arabic numerals on virtually all price tags). FR-14 / FR-20.
struct ReadCurrencyMenu: View {
    @Binding var value: String

    var body: some View {
        Menu {
            ForEach(Currencies.all) { c in
                Button("\(Currencies.flag(c.code))  \(c.code) — \(Currencies.displayName(c.code))") { value = c.code }
            }
        } label: {
            HStack(spacing: 8) {
                Text(Currencies.flag(value)).font(.system(size: 18))
                Text(value).font(.petal(16, .medium)).foregroundColor(Tokens.textPrimary)
                Text(Currencies.displayName(value)).font(.petal(13)).foregroundColor(Tokens.textDim).lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.down").font(.system(size: 12)).foregroundColor(Tokens.textDim)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Tokens.surface)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tokens.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityIdentifier("read-currency")
    }
}
