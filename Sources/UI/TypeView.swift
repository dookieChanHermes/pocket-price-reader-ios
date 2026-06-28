import SwiftUI

/// Type mode: enter an amount in the read currency, see it in up to 3 show currencies
/// live (FR-18/19), primary big + the rest compact (same hierarchy as Scan).
struct TypeView: View {
    let readCode: String
    let showCodes: [String]

    // Observe rates so the conversion re-renders when a live refresh lands (FR-5/FR-21).
    @ObservedObject private var rates = RatesStore.shared
    @State private var text: String = ProcessInfo.processInfo.environment["PPR_UITEST_VALUE"] ?? ""

    private var value: Double? { Double(text) }

    var body: some View {
        VStack(spacing: 26) {
            HStack(spacing: 8) {
                Text(Currencies.symbol(readCode))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Tokens.amber)
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
            }
            .overlay(Rectangle().frame(height: 2).foregroundColor(Tokens.line), alignment: .bottom)
            .padding(.bottom, 10)

            if let v = value {
                Readout(conversions: shownConversions(amount: v, from: readCode, showCodes: showCodes))
                Text("\(Currencies.symbol(readCode))\(formatGrouped(v)) \(readCode) at today’s rate")
                    .font(.system(size: 13))
                    .foregroundColor(Tokens.paperDim)
            } else {
                // FR-19: empty/invalid shows an em dash, no crash.
                Text("—").font(.system(size: 40, weight: .bold)).foregroundColor(Tokens.paper)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0x0a / 255, green: 0x0c / 255, blue: 0x10 / 255))
    }
}
