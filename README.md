# Pocket Price Reader — iOS

Point the phone at a foreign price tag and see it in your home currency, overlaid
on the live camera feed. Manual Type mode is the fallback. **All conversion works
offline.** Native iOS (SwiftUI), on-device OCR via Apple's **Vision** framework.

Implements the [Pocket Price Reader build spec](SPEC.md). Sibling of the native
Android app (`pocket-price-reader-android`); the logic is ported 1:1.

## v1.2 — "Petal" redesign

- **Cute kawaii theme** (sakura-blossom mascot "Petal", soft pink palette, rounded
  font, playful copy) replacing the old dark/amber look. New app icon.
- **Multi-currency**: pick one *read* currency (JPY/CNY/HKD, drives OCR) and an
  **ordered, reorderable list of up to 3 *show* currencies** (`Logic/ShowList.swift`,
  `Components/ShowCurrencyList.swift`) — numbered pill rows, move up/down, add/remove,
  persisted via `@AppStorage("showOrder")`. Primary (top) shows biggest.
- Conversion is a USD-based cross-rate `convert(amount, from, to)`; overlay numbers
  carry a dark halo so they stay legible over any camera feed. (The old Swap control
  is retired — read→show replaces it.)

## Stack

- **SwiftUI**, single-scene, iOS 17+.
- **Vision** `VNRecognizeTextRequest` — on-device text recognition (offline, no
  network, no model download). Languages follow the currency: `ja-JP` (JPY),
  `zh-Hans` (CNY), `en-US` (HKD), per FR-14.
- **AVFoundation** — `AVCaptureSession` back-camera feed + `AVCaptureVideoDataOutput`
  frame stream, recognition restricted to the band via Vision `regionOfInterest`.
- Rates fetched best-effort via `URLSession`, cached in `UserDefaults` (`rates.v1`),
  with a bundled fallback. `Codable` throughout.
- Project generated with **xcodegen** from `project.yml` (the `.xcodeproj` is not
  checked in).

## Build & run

Toolchain on this machine: Xcode 26.6 at `/Applications/Xcode.app` (but
`xcode-select` points at CommandLineTools, so prefix commands with `DEVELOPER_DIR`).

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SIM=D9029145-9D81-47E0-BDE0-DC0D52A1A404   # iPhone 17 simulator

brew install xcodegen          # if needed
cd ~/repos/pocket-price-reader-ios
xcodegen generate              # produce PocketPriceReader.xcodeproj from project.yml

# build + unit tests
xcodebuild -project PocketPriceReader.xcodeproj -scheme PocketPriceReader \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO test

# install + launch
APP=build/Build/Products/Debug-iphonesimulator/PocketPriceReader.app
xcrun simctl install "$SIM" "$APP"
xcrun simctl launch "$SIM" com.pocketpricereader
```

> The iOS Simulator has **no camera**, so Scan mode shows the "No camera found"
> state there — use Type mode on the simulator, and a physical device for live
> scanning of real price tags.

## Architecture (maps to spec §5)

```
Sources/
  PocketPriceReaderApp.swift   @main App
  Model/Currency.swift         Currency (code/symbol/name/flag), readCodes, →Vision languages (FR-14)
  Logic/Convert.swift          convert(_:from:to:); shownConversions() — pure (FR-1)
  Logic/ShowList.swift         ordered show-list ops: add/remove/move/setAt/serialize
  Logic/ParsePrice.swift       OCR text → Double? — faithful port of spec §7
  Logic/Format.swift           grouped / money number formatting (edge rounding)
  Data/RatesStore.swift        cache load / live refresh / bundled fallback (FR-5..10)
  OCR/PriceScanner.swift        AVCaptureSession + Vision, band ROI + frame-skip (FR-12..16)
  UI/RootView.swift            mode / read currency / ordered show-list state; rate bootstrap; panel
  UI/Components/ShowCurrencyList.swift  reorderable show-currency pill rows
  UI/ScannerView.swift         camera preview + permission + scan band + readout
  UI/TypeView.swift            manual numeric entry
  UI/Components/               CurrencySegment, Readout
  UI/Theme.swift               design tokens (§8)
Tests/                         ParsePriceTests, ConvertTests, ShowListTests, FormatTests, RatesTests
```

State lives in `RootView` and flows down. `RatesStore` is the only shared singleton
(the spec's `lib/rates.ts`); views that show conversions observe it so they
re-render when a live refresh lands (FR-5/FR-21).

## Offline / Great Firewall

- **OCR**: Apple Vision is fully on-device. Works in China unchanged, no network.
- **Rates**: `open.er-api.com` may be blocked. The app fetches when it can, caches
  the result, and ships a bundled fallback (`JPY 157.0, CNY 7.12, HKD 7.8`) so
  conversion always works. Open the app on wifi before the China leg to cache a
  fresh rate.

## Known spec note (parsePrice / AC-5)

Spec §7 gives the **exact** parse algorithm; §10 AC-5 also claims
`parsePrice("03-1234-5678")` returns `nil`. These conflict: the §7 algorithm
replaces the hyphens with spaces and splits into `03` / `1234` / `5678` (each in
range), so it returns `1234`. This port follows the **§7 algorithm** (matching the
reference implementation and the Android port) and documents the discrepancy in
`ParsePriceTests`. If true phone-number rejection is wanted, that's a deliberate
spec change to make explicitly.

## Verification status

- 66 unit tests green across 5 suites (`ParsePriceTests`, `ConvertTests`,
  `ShowListTests`, `FormatTests`, `RatesTests`), referencing AC/FR IDs.
- Verified on the iPhone 17 simulator: launch + camera-permission prompt (FR-17),
  graceful "No camera found" fallback (§8), live rate refresh + `rates.v1` source
  label (AC-4 / FR-10), and Type-mode conversion (`1500 → $9.28` at the live rate,
  AC-1) reacting to the live refresh (FR-5/FR-21).
- Real OCR on physical price tags requires a device (the simulator has no camera).
