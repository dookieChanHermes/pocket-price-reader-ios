import Foundation

/// Rate storage shape (spec §6, key `rates.v1`). `whenLabel` (`_when`) is a human
/// timestamp or the literal "bundled estimate".
struct Rates: Codable, Equatable {
    let JPY: Double
    let CNY: Double
    let HKD: Double
    let whenLabel: String

    enum CodingKeys: String, CodingKey {
        case JPY, CNY, HKD
        case whenLabel = "_when"
    }

    func rate(of cur: CurrencyCode) -> Double {
        switch cur {
        case .JPY: return JPY
        case .CNY: return CNY
        case .HKD: return HKD
        }
    }
}

/// Only the fields we consume from open.er-api.com (spec §6).
private struct ApiResponse: Codable {
    let rates: ApiRates?
}
private struct ApiRates: Codable {
    let JPY: Double
    let CNY: Double
    let HKD: Double
}

/// Single source of truth for rates (spec §7 lib/rates.ts). The bundled fallback ships
/// in the binary so conversion works on day one with no network — critical for the
/// China leg where the rate API may be unreachable.
///
/// Not actor-isolated: `current` is read synchronously by `convert()` from any context.
/// Published mutations are hopped to the main actor so SwiftUI updates cleanly.
final class RatesStore: ObservableObject {
    static let shared = RatesStore()

    // FR-9 bundled fallback.
    private static let fallback = Rates(JPY: 157.0, CNY: 7.12, HKD: 7.8, whenLabel: "bundled estimate")
    private static let key = "rates.v1"
    private static let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!

    @Published private(set) var current: Rates = RatesStore.fallback
    @Published private(set) var source: String = "offline · bundled"

    private init() {}

    /// FR-5 first half: load cached rates from storage. Never throws. Call on main.
    @MainActor
    func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let cached = try? JSONDecoder().decode(Rates.self, from: data) else { return }
        current = cached
        source = "cached · \(cached.whenLabel)"
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
            guard let r = parsed.rates else { throw URLError(.cannotParseResponse) } // EC-1 malformed

            let stamp = Self.stamp()
            let next = Rates(JPY: r.JPY, CNY: r.CNY, HKD: r.HKD, whenLabel: stamp)
            if let encoded = try? JSONEncoder().encode(next) {
                UserDefaults.standard.set(encoded, forKey: Self.key)
            }
            await MainActor.run {
                self.current = next
                self.source = "live · \(stamp)"
            }
        } catch {
            // offline: keep whatever we loaded from cache or the bundled fallback (FR-8).
            await MainActor.run {
                if !self.source.hasPrefix("cached") { self.source = "offline · bundled" }
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
    /// Test hook: pin rates deterministically (the unit-test bundle is hosted in the
    /// app, whose launch otherwise live-refreshes this shared singleton).
    func _setForTesting(_ r: Rates) {
        current = r
        source = "test"
    }
    static var _bundledFallback: Rates { fallback }
    #endif
}
