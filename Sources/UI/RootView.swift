import SwiftUI

enum Mode { case scan, type }

/// Reads an optional UI-test launch environment override (only set by automated
/// launches; never present in normal use).
private func uiTestEnv(_ key: String) -> String? {
    ProcessInfo.processInfo.environment[key]
}

/// Top-level: mode / currency / direction state, rate bootstrap, bottom panel.
/// State lives here and flows down (spec §5).
struct RootView: View {
    @State private var mode: Mode = Self.initialMode
    @State private var cur: CurrencyCode = .JPY        // FR-3 default JPY
    @State private var foreignToUsd: Bool = true        // FR-2 default
    @StateObject private var rates = RatesStore.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch mode {
                case .scan: ScannerView(cur: cur, foreignToUsd: foreignToUsd)
                case .type: TypeView(cur: cur, foreignToUsd: foreignToUsd)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomPanel
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            // FR-5: load cache → (already rendered) → live refresh → re-render.
            rates.loadCached()
            await rates.refresh()
        }
    }

    static var initialMode: Mode {
        uiTestEnv("PPR_UITEST_MODE") == "type" ? .type : .scan
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            // Mode switch (FR-20).
            HStack(spacing: 6) {
                ModeButton(label: "📷 Scan", on: mode == .scan) { mode = .scan }
                ModeButton(label: "⌨️ Type", on: mode == .type) { mode = .type }
            }

            CurrencySegment(value: $cur)

            // Swap + direction label (FR-4).
            HStack(spacing: 10) {
                Button(action: { foreignToUsd.toggle() }) {
                    Text("⇅ Swap")
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.paper)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Tokens.inkSoft)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tokens.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Text("\(inCurrency(cur, foreignToUsd: foreignToUsd)) → \(outCurrency(cur, foreignToUsd: foreignToUsd))")
                    .font(.system(size: 13))
                    .foregroundColor(Tokens.paperDim)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            // Rate meta line (FR-10).
            Text("1 USD = \(String(format: "%.2f", rates.current.rate(of: cur))) \(cur.rawValue) · rates: \(rates.source)")
                .font(.system(size: 11))
                .foregroundColor(Tokens.paperFaint)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Tokens.ink)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Tokens.line), alignment: .top)
    }
}

private struct ModeButton: View {
    let label: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(on ? Tokens.paper : Tokens.paperDim)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 4)
                .background(Tokens.inkSoft)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? Tokens.amber : Tokens.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
