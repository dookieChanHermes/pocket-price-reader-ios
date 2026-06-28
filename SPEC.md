# Pocket Price Reader — Build Spec

**Status:** authoritative. Implement against this file. When code and this spec
disagree, this spec wins unless a decision in §12 says otherwise.
**Audience:** the implementing agent(s). Each requirement has a stable ID
(`FR-*`, `NFR-*`, `AC-*`) — reference these IDs in commits, PRs, and tests.
**Repo:** `pocket-price-reader/` (Expo + TypeScript + react-native-vision-camera).

---

## 1. Goal & non-goals

**Goal.** A traveler points the phone at a foreign price tag and immediately
sees that price in their home currency, overlaid on the live camera feed. A
manual entry mode is the fallback. All conversion works offline.

**In scope (v1):** JPY, CNY, HKD ↔ USD. Camera OCR of numeric prices. Manual
entry. Live rates with offline cache + bundled fallback. Direction toggle.

**Out of scope (v1):** currencies beyond the three. Auto-detection of which
currency from the on-screen glyph (manual toggle instead). Receipt/multi-line
parsing. Translation. Accounts, sync, analytics.

---

## 2. Definitions

- **Foreign currency** — the selected one of {JPY, CNY, HKD}.
- **Direction** — `foreignToUsd` boolean. `true` (default) = read a foreign
  price, show USD. `false` = show USD amount in the foreign currency.
- **Rate** — value `r` such that `1 USD = r <foreign>`. Stored per currency.
- **Detected price** — the single number `parsePrice()` extracts from an OCR frame.

---

## 3. Functional requirements

### Conversion
- **FR-1** Convert a number given (currency, direction). `foreignToUsd` →
  `amount / r`; else `amount * r`. Source of truth: `lib/convert.ts`.
- **FR-2** Default direction is `foreignToUsd = true`.
- **FR-3** Default currency is `JPY`.
- **FR-4** Swap control inverts direction; the label and all outputs update
  immediately, with no re-fetch of rates.

### Rates
- **FR-5** On launch: load cached rates from storage, render, then attempt a
  live refresh and re-render. Never block first paint on the network.
- **FR-6** Live source: `GET https://open.er-api.com/v6/latest/USD`. Read
  `rates.JPY`, `rates.CNY`, `rates.HKD`.
- **FR-7** On successful fetch, persist `{JPY,CNY,HKD,_when}` to storage under
  key `rates.v1` and mark source `live`.
- **FR-8** On fetch failure, retain cached or bundled values. Never show an
  error that blocks conversion.
- **FR-9** Bundled fallback ships in the binary: `JPY 157.0, CNY 7.12, HKD 7.8`.
- **FR-10** Display the active rate for the selected currency and the source
  label (`live · <ts>` / `cached · <ts>` / `offline · bundled`).

### Scan mode
- **FR-11** Show the live back-camera feed full-bleed.
- **FR-12** Draw a fixed scan band (the OCR region) centered horizontally.
- **FR-13** Run on-device OCR on frames within the band only (region crop).
- **FR-14** OCR script follows currency: JPY→japanese, CNY→chinese, HKD→latin.
- **FR-15** Per recognized frame, run `parsePrice()`; if it returns a number,
  show detected value + converted value in the overlay.
- **FR-16** If no price is detected for >1500 ms, hide the overlay.
- **FR-17** Camera permission: request on entry; if denied, show a non-blocking
  message and a deep link to system settings. Type mode remains usable.

### Type mode
- **FR-18** Numeric keypad input. As the value changes, show the converted
  amount and a subline restating the input in its currency.
- **FR-19** Empty/invalid input shows `—`, no crash.

### Shared UI
- **FR-20** Mode switch (Scan / Type) and currency segment (JPY/CNY/HKD) are
  always visible in the bottom panel.
- **FR-21** Changing currency or direction updates Scan and Type outputs live.

---

## 4. Non-functional requirements

- **NFR-1 Offline-first.** OCR must require no network. Conversion must work
  with zero connectivity using cached or bundled rates. No CDN at runtime.
- **NFR-2 GFW-safe.** No dependency that is fetched at runtime from a host
  likely blocked in mainland China. Rate fetch is best-effort only.
- **NFR-3 Performance.** OCR throttled via frame-skip; UI stays at 60fps; the
  detected-value overlay updates without visible jank.
- **NFR-4 Accessibility.** Overlay text legible over arbitrary feeds (shadow /
  contrast). Respect OS dark theme. Touch targets ≥ 44pt.
- **NFR-5 Battery.** Camera/OCR only active while Scan mode is foregrounded;
  release on mode switch / background.

---

## 5. Architecture & file map

```
src/
  App.tsx                 mode/currency/direction state; rate bootstrap; panel
  theme.ts                tokens; SYMBOL; OCR_LANGUAGE
  lib/
    rates.ts              load/refresh/get; storage; bundled fallback
    convert.ts            convert(); inCurrency(); outCurrency()
    parsePrice.ts         OCR text → number | null
  screens/
    ScannerScreen.tsx     camera + OCR callback + band + Readout
    TypeScreen.tsx        manual entry
  components/
    CurrencySegment.tsx   JPY/CNY/HKD selector
    Readout.tsx           overlay (detected + converted)
```

State lives in `App.tsx` and flows down as props. No global store in v1.

---

## 6. Data contracts

### Rate storage (`rates.v1`)
```ts
type Rates = { JPY: number; CNY: number; HKD: number; _when: string };
```
`_when` is a human timestamp or the literal `"bundled estimate"`.

### Rate API response (only fields consumed)
```ts
{ result: "success"; rates: { JPY: number; CNY: number; HKD: number; /* … */ } }
```

### OCR callback result (verify against installed lib version, see §11)
```ts
type OcrText = { resultText: string; blocks: unknown[] };
```
Only `resultText` is consumed in v1.

---

## 7. Module contracts

### `lib/convert.ts`
```ts
convert(amount: number, cur: CurrencyCode, foreignToUsd: boolean): number
inCurrency(cur, foreignToUsd): string   // foreignToUsd ? cur : "USD"
outCurrency(cur, foreignToUsd): string  // foreignToUsd ? "USD" : cur
```
Pure. No side effects. No rounding inside `convert` — format at the edge.

### `lib/parsePrice.ts`
```ts
parsePrice(raw: string): number | null
```
Algorithm (exact):
1. Normalize full-width digits `U+FF10–U+FF19` → ASCII; `U+FF0C`→`,`; `U+FF0E`→`.`.
2. Replace every char not in `[0-9.,\s]` with a space; trim.
3. Split on whitespace. For each token: strip thousands commas
   (`,` followed by exactly 3 digits), convert any remaining `,` to `.`.
4. `parseFloat`; keep if `1 ≤ n < 100_000_000`.
5. Among kept values, return the one whose **token string is longest**
   (longest digit run ≈ the real price, not an aisle number). Ties: first.
6. No candidates → `null`.

### `lib/rates.ts`
```ts
loadCachedRates(): Promise<void>   // FR-5 first half; never throws
refreshRates(): Promise<void>      // FR-6..8; never throws
getRates(): Rates
getSource(): string
```

---

## 8. UI spec

**Tokens** (`theme.ts`): `ink #0f1115`, `inkSoft #1a1e26`, `amber #f4b942`,
`amberDeep #c8861f`, `paper #f7f4ec`, `good #6fcf97`, `line rgba(255,255,255,.10)`.
Numbers use tabular figures everywhere they appear.

**Scan band:** centered, `left/right 6%`, `top 40%`, `height 20%`, 2px amber
border, 14px radius. The OCR `scanRegion` MUST match these values.

**Readout overlay:** above the band. Line 1 = detected price in input currency,
dim. Line 2 = converted value, 46pt bold, currency symbol in amber, heavy text
shadow for legibility. Hidden when no detection (FR-16).

**Bottom panel:** mode switch row → currency segment → swap + direction label →
rate meta line.

**Empty/error copy** (interface voice, not apologetic):
- No camera permission: "Allow camera access to read prices. Type mode works
  without it." + "Open Settings".
- No back camera: "This device has no usable back camera."

---

## 9. Edge cases

- **EC-1** Rate fetch returns malformed JSON → treat as failure (FR-8).
- **EC-2** OCR fires rapidly with flickering reads → last valid wins; 1500ms
  grace before hiding (FR-16).
- **EC-3** Detected price is `0` or noise like a phone number → excluded by the
  `1 ≤ n < 1e8` bound; long IDs (e.g. 10+ digits) are filtered by the upper bound.
- **EC-4** Currency switched mid-scan → OCR language and outputs update on next
  frame; no stale conversion shown.
- **EC-5** App backgrounded in Scan → camera released; resumes on foreground.
- **EC-6** Cache older than 48h → still used; surface a soft "rates may be
  stale" note (see FR-10 extension, optional in v1).

---

## 10. Acceptance criteria (Given/When/Then)

- **AC-1 (FR-1,FR-2)** Given JPY and default direction, when input is `1500`,
  then output ≈ `1500 / rate.JPY` USD, rendered with `$` and ≤2 decimals.
- **AC-2 (FR-4)** Given any state, when Swap is tapped, then the direction label
  flips, outputs recompute, and no network call is made.
- **AC-3 (FR-5,FR-8)** Given no connectivity at launch, when the app opens, then
  conversion works using cached or bundled rates and the source reads
  `offline · bundled` (or `cached · …`).
- **AC-4 (FR-7)** Given connectivity, when refresh succeeds, then storage key
  `rates.v1` holds the new values and source reads `live · <ts>`.
- **AC-5 (parsePrice)** Given OCR text `"￥１，５００"`, then `parsePrice` returns
  `1500`. Given `"Aisle 3  ¥980"`, returns `980`. Given `"no price"`, returns
  `null`. Given `"03-1234-5678"`, returns `null` (out of bounds).
- **AC-6 (FR-16)** Given a detection then 1500ms with none, the overlay hides.
- **AC-7 (FR-17)** Given camera permission denied, then Scan shows the settings
  prompt and Type mode still converts.
- **AC-8 (FR-14)** Given currency CNY, the OCR recognizer is initialized with
  the `chinese` script; for JPY, `japanese`; for HKD, `latin`.

---

## 11. Test matrix

| Area | Cases |
|---|---|
| parsePrice (unit) | full-width digits; thousands separators; decimal comma; surrounding text; out-of-range; empty; multiple numbers (longest wins) |
| convert (unit) | both directions × 3 currencies; formatting/rounding at edge |
| rates (unit, mocked fetch) | success persists + source; failure keeps cache; malformed JSON; cold start with empty storage |
| Scan (integration, device) | permission grant/deny; detection→overlay; 1500ms hide; currency switch mid-scan; background/foreground release |
| Type (integration) | valid/invalid/empty; swap; currency switch |
| Offline (device) | airplane mode launch; airplane mode after one live fetch |

Unit tests must reference the AC/FR IDs they cover.

---

## 12. Decisions & open questions

**Decided.**
- D-1 Manual currency toggle, not glyph auto-detection, in v1 (reliability).
- D-2 Default direction foreign→USD (traveler reading a local price).
- D-3 On-device ML Kit OCR over any cloud/CDN OCR (NFR-1/2).

**Open — confirm before/while building.**
- Q-1 OCR library prop surface. `react-native-vision-camera-ocr-plus` has
  changed `mode` / `options.language` / `scanRegion` / `callback` across
  majors. **The implementing agent must read the installed version's README and
  adapt `ScannerScreen.tsx` accordingly.** The convert/parse/rate layers are
  version-independent and must not change to accommodate it.
- Q-2 Stale-rate warning (EC-6) — ship in v1 or defer?
- Q-3 Tap-to-lock a detected price (freeze frame) — v1 or v1.1?

---

## 13. Definition of done (v1)

All FR/NFR met; AC-1…AC-8 pass; unit suites green; a device build reads a real
JPY price tag and shows USD; airplane-mode launch still converts; README build
steps reproduce from a clean clone.
