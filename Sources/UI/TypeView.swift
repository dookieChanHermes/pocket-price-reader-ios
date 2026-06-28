import SwiftUI

/// Type mode: numeric keypad entry with live conversion (FR-18/19).
struct TypeView: View {
    let cur: CurrencyCode
    let foreignToUsd: Bool

    // Observe rates so the conversion re-renders when a live refresh lands (FR-5/FR-21).
    @ObservedObject private var rates = RatesStore.shared
    @State private var text: String = ProcessInfo.processInfo.environment["PPR_UITEST_VALUE"] ?? ""

    private var value: Double? { Double(text) }

    var body: some View {
        let inCur = inCurrency(cur, foreignToUsd: foreignToUsd)
        let outCur = outCurrency(cur, foreignToUsd: foreignToUsd)

        VStack(spacing: 26) {
            TextField("", text: $text, prompt: Text("0").foregroundColor(Tokens.line))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 54))
                .monospacedDigit()
                .foregroundColor(Tokens.paper)
                .tint(Tokens.amber)
                .onChange(of: text) { _, newValue in
                    text = newValue.filter { $0.isNumber || $0 == "." }
                }
                .overlay(Rectangle().frame(height: 2).foregroundColor(Tokens.line), alignment: .bottom)
                .padding(.bottom, 10)

            VStack(spacing: 6) {
                if let v = value {
                    (Text(symbol(of: outCur)).font(.system(size: 22)).foregroundColor(Tokens.amber)
                        + Text(formatMoney(convert(v, cur, foreignToUsd: foreignToUsd)))
                            .font(.system(size: 40, weight: .bold)).foregroundColor(Tokens.paper))
                        .monospacedDigit()

                    Text("\(symbol(of: inCur))\(formatGrouped(v)) \(inCur) at today’s rate")
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.paperDim)
                } else {
                    // FR-19: empty/invalid shows an em dash, no crash.
                    Text("—").font(.system(size: 40, weight: .bold)).foregroundColor(Tokens.paper)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0x0a / 255, green: 0x0c / 255, blue: 0x10 / 255))
    }
}
