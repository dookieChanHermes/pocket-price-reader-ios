import SwiftUI

/// Type mode: enter an amount in the read currency, see it in up to 3 show currencies
/// live (FR-18/19), primary big + the rest compact (same hierarchy as Scan).
struct TypeView: View {
    let readCode: String
    let showCodes: [String]

    @ObservedObject private var rates = RatesStore.shared
    @State private var text: String = ProcessInfo.processInfo.environment["PPR_UITEST_VALUE"] ?? ""

    private var value: Double? { Double(text) }

    var body: some View {
        VStack(spacing: 26) {
            HStack(spacing: 8) {
                Text(Currencies.symbol(readCode))
                    .font(.petal(30, .medium))
                    .foregroundColor(Tokens.primary)
                TextField("", text: $text, prompt: Text("0").foregroundColor(Tokens.textFaint))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.petal(54, .medium))
                    .monospacedDigit()
                    .foregroundColor(Tokens.textPrimary)
                    .tint(Tokens.primary)
                    .onChange(of: text) { _, newValue in
                        // ASCII digits only (matches Android's Char.isDigit); rejects ½, ², etc.
                        text = newValue.filter { ($0.isASCII && $0.isNumber) || $0 == "." }
                    }
            }
            .overlay(Rectangle().frame(height: 2).foregroundColor(Tokens.line), alignment: .bottom)
            .padding(.bottom, 10)

            if let v = value {
                TypeReadout(conversions: shownConversions(amount: v, from: readCode, showCodes: showCodes))
                Text("\(Currencies.symbol(readCode))\(formatGrouped(v)) \(readCode) \(Copy.todayRateSuffix)")
                    .font(.petal(13))
                    .foregroundColor(Tokens.textDim)
            } else {
                Text(Copy.emptyDash).font(.petal(40, .medium)).foregroundColor(Tokens.textFaint)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.typeBg)
    }
}

/// Like Readout but tuned for the light Type screen (dark text, no halo).
private struct TypeReadout: View {
    let conversions: [ShownConversion]

    var body: some View {
        VStack(spacing: 6) {
            if let primary = conversions.first {
                (Text(primary.symbol).font(.petal(24, .medium)).foregroundColor(Tokens.primary)
                    + Text(primary.value).font(.petal(44, .medium)).foregroundColor(Tokens.textPrimary))
                    .monospacedDigit()
            }
            if conversions.count > 1 {
                HStack(spacing: 18) {
                    ForEach(conversions.dropFirst()) { c in
                        (Text(c.symbol).font(.petal(18, .medium)).foregroundColor(Tokens.primary)
                            + Text(c.value).font(.petal(22, .medium)).foregroundColor(Tokens.textDim))
                            .monospacedDigit()
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
    }
}
