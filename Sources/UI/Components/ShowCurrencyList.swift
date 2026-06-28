import SwiftUI

/// "Show in" — the ordered list of up to 3 currencies the overlay/Type output displays.
/// Numbered pastel pill rows; reorder with up/down (primary = top = biggest), change the
/// currency via a tap menu, remove (keeping >= 1), and add until 3. Backed by ShowList.
struct ShowCurrencyList: View {
    @Binding var show: [String]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(show.enumerated()), id: \.element) { index, code in
                row(index: index, code: code)
            }
            if show.count < ShowList.maxCount { addRow }
        }
    }

    private func row(index: Int, code: String) -> some View {
        HStack(spacing: 10) {
            // numbered rank badge (1 mint, 2 pink, 3 deep)
            Text("\(index + 1)")
                .font(.petal(13, .medium))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Tokens.badge(index))
                .clipShape(Circle())

            // tap to change this slot's currency
            Menu {
                ForEach(Currencies.all) { c in
                    Button("\(Currencies.flag(c.code))  \(c.code) — \(Currencies.displayName(c.code))") {
                        show = ShowList.setAt(show, index, c.code)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(Currencies.flag(code)).font(.system(size: 17))
                    Text(code).font(.petal(15, .medium)).foregroundColor(Tokens.textPrimary)
                    Image(systemName: "chevron.down").font(.system(size: 10)).foregroundColor(Tokens.textDim)
                }
            }

            if index == 0 {
                Text(Copy.primaryTag)
                    .font(.petal(11, .medium))
                    .foregroundColor(Tokens.primaryDeep)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Tokens.tagBg)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 4)

            iconButton("chevron.up", enabled: index > 0) { show = ShowList.moveUp(show, index) }
            iconButton("chevron.down", enabled: index < show.count - 1) { show = ShowList.moveDown(show, index) }
            if show.count > 1 {
                iconButton("xmark", enabled: true, tint: Tokens.primaryDeep) { show = ShowList.removeAt(show, index) }
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 46)
        .background(Tokens.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tokens.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var addRow: some View {
        let remaining = Currencies.all.filter { !show.contains($0.code) }
        return Menu {
            ForEach(remaining) { c in
                Button("\(Currencies.flag(c.code))  \(c.code) — \(Currencies.displayName(c.code))") {
                    show = ShowList.add(show, c.code)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 13, weight: .medium))
                Text(Copy.addCurrency).font(.petal(14))
            }
            .foregroundColor(Tokens.textDim)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Tokens.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        }
    }

    private func iconButton(_ name: String, enabled: Bool, tint: Color = Tokens.primary, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            Image(systemName: name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(enabled ? tint : Tokens.textFaint.opacity(0.5))
                .frame(width: 30, height: 30)
                .background(Tokens.panelBg)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }
}
