import SwiftUI

enum Mode { case scan, type }

private func uiTestEnv(_ key: String) -> String? {
    ProcessInfo.processInfo.environment[key]
}

/// Top-level: mode + read currency + an ordered, reorderable list of up to 3 "show"
/// currencies (persisted), rate bootstrap, and the cute bottom panel. State lives here
/// and flows down (spec §5).
struct RootView: View {
    @State private var mode: Mode = Self.initialMode
    @State private var keyboardUp = false
    @State private var prefill: String? = nil   // scanned digits handed to Type mode for correction
    @StateObject private var rates = RatesStore.shared

    @AppStorage("readCode") private var readCode: String = "JPY"   // FR-3
    @AppStorage("showOrder") private var showOrder: String = "USD" // ordered show list

    private var showCodes: [String] { ShowList.deserialize(showOrder) }

    private var showBinding: Binding<[String]> {
        Binding(
            get: { ShowList.deserialize(showOrder) },
            set: { showOrder = ShowList.serialize(ShowList.sanitize($0)) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch mode {
                case .scan:
                    ScannerView(readCode: readCode, showCodes: showCodes) { detected in
                        prefill = Self.numericString(detected)   // tap the scanned price to fix it
                        mode = .type
                    }
                case .type:
                    TypeView(readCode: readCode, showCodes: showCodes,
                             keyboardUp: $keyboardUp, initialText: prefill)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Only the full-bleed camera extends under the status bar / Dynamic Island;
            // the Type screen respects the top safe area so its content is never clipped.
            .ignoresSafeArea(.container, edges: mode == .scan ? .top : [])

            // While typing, the keyboard covers the controls anyway — hide the (tall) panel
            // so the input + conversions sit comfortably above the keyboard, never clipped.
            if !(mode == .type && keyboardUp) {
                bottomPanel
            }
        }
        .background(Tokens.panelBg.ignoresSafeArea())
        // Light app appearance (the panel/Type are light); status bar is forced to dark
        // content in Info.plist so the clock/battery read on the light UI and typical feeds.
        .preferredColorScheme(.light)
        .task {
            migrateAndNormalizeShowOrder()
            applyUITestOverrides()
            rates.loadCached()
            await rates.refresh()
        }
    }

    static var initialMode: Mode {
        uiTestEnv("PPR_UITEST_MODE") == "type" ? .type : .scan
    }

    /// Clean numeric string to pre-fill Type mode from a scanned value (e.g. 1399.0 -> "1399"),
    /// so the user can drop in a missing decimal point in one tap.
    static func numericString(_ d: Double) -> String {
        if d == d.rounded() && abs(d) < 1e15 { return String(Int(d)) }
        return String(d)
    }

    /// One-time migration from the v1.1 per-slot keys (show1/show2/show3) to the v1.2
    /// ordered "showOrder", and canonicalize the stored string so it always matches the
    /// displayed (sanitized) list.
    private func migrateAndNormalizeShowOrder() {
        let d = UserDefaults.standard
        if d.string(forKey: "showOrder") == nil {
            let legacy = ["show1", "show2", "show3"]
                .compactMap { d.string(forKey: $0) }
                .filter { !$0.isEmpty }
            if !legacy.isEmpty {
                showOrder = ShowList.serialize(ShowList.sanitize(legacy))
            }
        } else {
            showOrder = ShowList.serialize(ShowList.deserialize(showOrder))
        }
    }

    private func applyUITestOverrides() {
        if let r = uiTestEnv("PPR_UITEST_READ") { readCode = r }
        if let s = uiTestEnv("PPR_UITEST_SHOW") { showOrder = ShowList.serialize(ShowList.deserialize(s)) }
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ModeButton(label: Copy.scanMode, on: mode == .scan) { mode = .scan }
                // Manual Type starts empty; the pre-filled path is the scanned-price tap.
                ModeButton(label: Copy.typeMode, on: mode == .type) { prefill = nil; mode = .type }
            }

            VStack(alignment: .leading, spacing: 6) {
                sectionLabel(Copy.readingLabel)
                ReadCurrencyMenu(value: $readCode)
            }

            VStack(alignment: .leading, spacing: 6) {
                sectionLabel(Copy.showLabel)
                ShowCurrencyList(show: showBinding)
            }

            VStack(spacing: 2) {
                Text("\(Copy.ratesLabel) \(rates.source)")
                    .font(.petal(11))
                    .foregroundColor(Tokens.textDim)
                Link(Copy.rateAttribution,
                     destination: URL(string: "https://www.exchangerate-api.com")!)
                    .font(.petal(11))
                    .foregroundColor(Tokens.textDim)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Tokens.panelBg)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Tokens.line), alignment: .top)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.petal(12))
            .tracking(0.4)
            .foregroundColor(Tokens.textDim)
    }
}

private struct ModeButton: View {
    let label: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.petal(15, .medium))
                .foregroundColor(on ? Tokens.onPrimary : Tokens.textDim)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(on ? Tokens.primary : Tokens.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Color.clear : Tokens.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
