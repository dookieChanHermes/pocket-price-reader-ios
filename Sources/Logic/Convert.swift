import Foundation

/// Cross-rate conversion (FR-1, generalized). Rates are USD-based (1 USD = rate[code]),
/// so `amount` of `from` in `to` is `amount / rate[from] * rate[to]`. Pure given the
/// current rate table. No rounding here — format at the edge (spec §7).
func convert(_ amount: Double, from: String, to: String) -> Double {
    let rates = RatesStore.shared.current
    let rFrom = rates.rate(of: from)
    let rTo = rates.rate(of: to)
    guard rFrom > 0 else { return 0 }
    return amount / rFrom * rTo
}

/// One displayed conversion (symbol + formatted value).
struct ShownConversion: Identifiable {
    let code: String
    let symbol: String
    let value: String
    var id: String { code }
}

/// Build the ordered list of conversions to display (first = primary). Skips empty
/// (None) slots, so the result has 1–3 entries.
func shownConversions(amount: Double, from readCode: String, showCodes: [String]) -> [ShownConversion] {
    showCodes
        .filter { !$0.isEmpty }
        .map { code in
            ShownConversion(
                code: code,
                symbol: Currencies.symbol(code),
                value: formatMoney(convert(amount, from: readCode, to: code))
            )
        }
}
