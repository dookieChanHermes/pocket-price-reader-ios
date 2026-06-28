import SwiftUI

/// A dropdown for one "show" currency slot. `code` is "" when the slot is None
/// (only allowed for the optional 2nd/3rd slots).
struct CurrencyMenu: View {
    let caption: String
    @Binding var code: String
    let allowNone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.system(size: 11))
                .foregroundColor(Tokens.paperFaint)

            Menu {
                if allowNone {
                    Button("None") { code = "" }
                }
                ForEach(Currencies.all) { c in
                    Button("\(c.code) — \(c.name)") { code = c.code }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(code.isEmpty ? "None" : "\(Currencies.symbol(code)) \(code)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(code.isEmpty ? Tokens.paperDim : Tokens.paper)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Tokens.paperDim)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(Tokens.inkSoft)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tokens.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
