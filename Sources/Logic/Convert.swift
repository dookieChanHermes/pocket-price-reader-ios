import Foundation

/// Direction-aware conversion (FR-1). Reads the current rate table (RatesStore).
/// `foreignToUsd` true  -> amount / rate  (read a foreign price, show USD)
/// `foreignToUsd` false -> amount * rate  (show a USD amount in the foreign currency)
/// No rounding here — format at the edge (spec §7).
func convert(_ amount: Double, _ cur: CurrencyCode, foreignToUsd: Bool) -> Double {
    let rate = RatesStore.shared.current.rate(of: cur) // 1 USD = rate foreign
    return foreignToUsd ? amount / rate : amount * rate
}

func inCurrency(_ cur: CurrencyCode, foreignToUsd: Bool) -> String {
    foreignToUsd ? cur.rawValue : "USD"
}

func outCurrency(_ cur: CurrencyCode, foreignToUsd: Bool) -> String {
    foreignToUsd ? "USD" : cur.rawValue
}
