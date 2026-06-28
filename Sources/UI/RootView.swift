import SwiftUI

enum Mode { case scan, type }

/// Reads an optional UI-test launch environment override (only set by automated
/// launches; never present in normal use).
private func uiTestEnv(_ key: String) -> String? {
    ProcessInfo.processInfo.environment[key]
}

/// Top-level: mode + read currency + up to 3 persisted "show" currencies, rate
/// bootstrap, bottom panel. State lives here and flows down (spec §5).
struct RootView: View {
    @State private var mode: Mode = Self.initialMode
    @StateObject private var rates = RatesStore.shared

    // Persisted selections (FR: "pre-select up to 3 ... and persist").
    @AppStorage("readCode") private var readCode: String = "JPY"   // read/scan currency (FR-3)
    @AppStorage("show1") private var show1: String = "USD"          // primary (required)
    @AppStorage("show2") private var show2: String = ""            // optional
    @AppStorage("show3") private var show3: String = ""            // optional

    private var showCodes: [String] { [show1, show2, show3] }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch mode {
                case .scan: ScannerView(readCode: readCode, showCodes: showCodes)
                case .type: TypeView(readCode: readCode, showCodes: showCodes)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomPanel
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            applyUITestOverrides()
            rates.loadCached()      // FR-5: cache → (rendered) → live refresh → re-render
            await rates.refresh()
        }
    }

    static var initialMode: Mode {
        uiTestEnv("PPR_UITEST_MODE") == "type" ? .type : .scan
    }

    private func applyUITestOverrides() {
        if let r = uiTestEnv("PPR_UITEST_READ") { readCode = r }
        if let s = uiTestEnv("PPR_UITEST_SHOW1") { show1 = s }
        if let s = uiTestEnv("PPR_UITEST_SHOW2") { show2 = s }
        if let s = uiTestEnv("PPR_UITEST_SHOW3") { show3 = s }
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ModeButton(label: "📷 Scan", on: mode == .scan) { mode = .scan }
                ModeButton(label: "⌨️ Type", on: mode == .type) { mode = .type }
            }

            // Read currency (drives OCR).
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading").font(.system(size: 11)).foregroundColor(Tokens.paperFaint)
                ReadSegment(value: $readCode)
            }

            // Up to 3 "show" currencies (persisted).
            HStack(alignment: .top, spacing: 8) {
                CurrencyMenu(caption: "Primary", code: $show1, allowNone: false)
                CurrencyMenu(caption: "2nd", code: $show2, allowNone: true)
                CurrencyMenu(caption: "3rd", code: $show3, allowNone: true)
            }

            Text("rates: \(rates.source)")
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
