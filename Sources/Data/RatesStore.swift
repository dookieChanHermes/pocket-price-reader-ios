import Foundation

/// Rate table: USD-based map (1 USD = value units of each code) plus a human
/// timestamp / "bundled estimate" label (spec §6, key `rates.v1`).
struct Rates: Codable, Equatable {
    let map: [String: Double]
    let whenLabel: String

    enum CodingKeys: String, CodingKey {
        case map
        case whenLabel = "_when"
    }

    /// 1 USD = rate(of: code) units of `code`. USD is the base (1.0).
    func rate(of code: String) -> Double {
        if code == "USD" { return 1.0 }
        return map[code] ?? Rates.fallbackMap[code] ?? .nan
    }

    /// Bundled offline estimates (1 USD = X). Cover the whole curated travel list so
    /// any selected currency converts offline — critical behind the Great Firewall.
    static let fallbackMap: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.78, "JPY": 157.0, "CNY": 7.12, "HKD": 7.8,
        "KRW": 1370, "TWD": 32.3, "SGD": 1.35, "THB": 36.5, "AUD": 1.51, "CAD": 1.37,
        "CHF": 0.89, "NZD": 1.64, "MYR": 4.7, "VND": 25400, "INR": 83.5, "IDR": 16200,
        "PHP": 58.5, "MXN": 18.3,
    ]
}

/// Only the field we consume from open.er-api.com (spec §6): the full USD-based map.
private struct ApiResponse: Codable {
    let rates: [String: Double]?
}

/// Single source of truth for rates (spec §7 lib/rates.ts). Bundled fallback ships in
/// the binary so conversion works on day one with no network.
final class RatesStore: ObservableObject {
    static let shared = RatesStore()

    private static let key = "rates.v1"
    private static let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!
    private static let fallback = Rates(map: Rates.fallbackMap, whenLabel: "bundled estimate")

    /// Freshness of the rates currently in use (drives the localised source label).
    enum RateSource { case offline, cached, live }

    @Published private(set) var current: Rates = RatesStore.fallback
    @Published private(set) var sourceKind: RateSource = .offline
    @Published private(set) var sourceStamp: String = ""

    /// Localised "source" label, e.g. "live · 2:00 PM" / "ライブ · 14:00".
    var source: String {
        switch sourceKind {
        case .offline: return String(localized: "rate_source_offline")
        case .cached: return "\(String(localized: "rate_source_cached")) · \(sourceStamp)"
        case .live: return "\(String(localized: "rate_source_live")) · \(sourceStamp)"
        }
    }

    private init() {}

    /// FR-5 first half: load cached rates from storage. Never throws. Call on main.
    @MainActor
    func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let cached = try? JSONDecoder().decode(Rates.self, from: data) else { return }
        current = cached
        sourceKind = .cached
        sourceStamp = cached.whenLabel
    }

    /// FR-6..8: best-effort live refresh; persist + mark source on success. Never throws.
    func refresh() async {
        do {
            var request = URLRequest(url: Self.endpoint)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 6
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let parsed = try JSONDecoder().decode(ApiResponse.self, from: data)
            guard let rates = parsed.rates, !rates.isEmpty else {
                throw URLError(.cannotParseResponse) // EC-1 malformed
            }
            let stamp = Self.stamp()
            let next = Rates(map: rates, whenLabel: stamp)
            if let encoded = try? JSONEncoder().encode(next) {
                UserDefaults.standard.set(encoded, forKey: Self.key)
            }
            await MainActor.run {
                self.current = next
                self.sourceKind = .live
                self.sourceStamp = stamp
            }
        } catch {
            await MainActor.run {
                if self.sourceKind != .cached {
                    self.sourceKind = .offline
                    self.sourceStamp = ""
                }
            }
        }
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: Date())
    }

    #if DEBUG
    func _setForTesting(_ r: Rates) {
        current = r
    }
    static var _bundledFallback: Rates { fallback }
    #endif
}
