import Foundation

private let groupedFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = Locale(identifier: "en_US")
    f.usesGroupingSeparator = true
    f.maximumFractionDigits = 3 // JS Number.toLocaleString default
    f.minimumFractionDigits = 0
    return f
}()

private let moneyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = Locale(identifier: "en_US")
    f.usesGroupingSeparator = true
    f.maximumFractionDigits = 2 // toLocaleString(maximumFractionDigits: 2)
    f.minimumFractionDigits = 0
    return f
}()

/// Grouped number, up to 3 fraction digits (e.g. 1500 -> "1,500").
func formatGrouped(_ n: Double) -> String {
    groupedFormatter.string(from: NSNumber(value: n)) ?? String(n)
}

/// Money output: grouped, up to 2 fraction digits.
func formatMoney(_ n: Double) -> String {
    moneyFormatter.string(from: NSNumber(value: n)) ?? String(n)
}
