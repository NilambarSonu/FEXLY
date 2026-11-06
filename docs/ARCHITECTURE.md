# Skylet Architecture

Skylet is engineered as a native macOS utility designed to run inside **Droppy** via the **DroppyKit SDK**, dedicated to **Figma-Faithful Currency Conversion, Real-Time FX & Historical Trend Intelligence**.

```
┌────────────────────────────────────────────────────────┐
│                        Droppy                          │
│  (Host Application: Dynamic Island, Shelf & Settings)  │
└───────────────────────────┬────────────────────────────┘
                            │ Dynamic Linkage
┌───────────────────────────▼────────────────────────────┐
│                    Skylet.droplet                      │
│  ┌───────────────────────┐  ┌────────────────────────┐ │
│  │   SkyletPrincipal     │  │     SkyletDroplet      │ │
│  └───────────────────────┘  └───────────┬────────────┘ │
│                                         │              │
│  ┌───────────────────────┐              │              │
│  │     SkyletRootView    │◄─────────────┤              │
│  │   CurrencyView        │              │              │
│  │   HistoricalGraphView │              │              │
│  │   CurrencySelectorView│              │              │
│  │   SettingsView        │              │              │
│  └───────────────────────┘              │              │
└─────────────────────────────────────────┼──────────────┘
                                          │
                               ┌──────────▼───────────┐
                               │     SkyletCore       │
                               │  - CurrencyParser    │
                               │  - RateService       │
                               │  - HistoryService    │
                               │  - TwelveData        │
                               │  - Frankfurter       │
                               │  - HistoryCache      │
                               │  - KeychainManager   │
                               └──────────────────────┘
```

## Modular Components

### 1. `SkyletCore` (Pure Swift Foundation Layer)
- **Zero UI / Host Coupling**: Independent of DroppyKit's dynamic bundle loader, enabling instant deterministic unit testing.
- **`CurrencyParser`**: Local tokenizer extracting numerical values, currency symbols, ISO codes, and aliases. Handles ambiguous symbols (`$`, `¥`, `Rs`) by yielding candidate lists rather than guessing silently. Supports US, European, and Indian grouping formats.
- **`CurrencyRateService` & Spot Providers**:
  - `TwelveDataRateProvider`: Preferred real-time Forex provider querying `https://api.twelvedata.com/exchange_rate` using header authentication (`Authorization: apikey`). Returns live quotes, timestamps, and rate freshness indicators.
  - `ExchangeRateAPIProvider`: Primary daily reference rate fallback (`https://open.er-api.com/v6/latest/{BASE}`) supporting 162 currencies.
  - `FrankfurterRateProvider`: Secondary ECB daily reference rate fallback.
  - `CurrencyRateCache`: Thread-safe cache with pair-specific 5-minute live TTL, 72-hour weekend delayed retention, and strict cache isolation to avoid test mock pollution.
  - Request deduplication: in-flight concurrent requests for the same pair share a single network task.
  - Pure `Decimal` arithmetic using `NSDecimalMultiply` for zero floating-point roundoff errors.
- **`CurrencyHistoryService` & Historical Providers**:
  - `TwelveDataHistoryProvider`: Primary historical engine querying `GET https://api.twelvedata.com/time_series` with header authentication (`Authorization: apikey ...`), mapping ranges to intervals (`1D` ➔ 15min, `5D` ➔ 1h, `1M`/`1Y` ➔ 1day, `5Y` ➔ 1week, `Max` ➔ 1month). Normalizes results into chronological ascending order with Decimal precision.
  - `FrankfurterHistoryProvider`: Open European Central Bank daily reference rates for `1M`, `1Y`, `5Y`, and `Max`. Strictly rejects intraday requests (`1D`, `5D`) with typed errors when no Twelve Data API key is configured.
  - `CurrencyHistoryCache`: Actor-based memory and disk persistence with interval-tailored TTLs (5m for intraday, 12h for 1M/1Y, 24h for 5Y/Max) and concurrent in-flight deduplication.
- **`MacOSKeychainManager`**:
  - Secure credential storage using Apple's native `Security` framework (`kSecClassGenericPassword`).
  - Stores user's personal Twelve Data API key locally in macOS Keychain without logging or persisting in repositories.

### 2. `Skylet` (SwiftUI & DroppyKit Presentation Layer)
- **`SkyletPrincipal`**: Instantiated by Droppy's bundle loader (`NSPrincipalClass`).
- **`SkyletDroplet`**: Entry point conforming to:
  - `Droplet`: Core lifecycle (`activate(host:)`, `deactivate()`).
  - `ShelfWidgetProviding`: Solo (420pt) and Paired (210pt) layouts on Droppy's shelf.
  - `LiveActivityProviding`: Publishes live source and converted amounts in the notch wings.
  - `SettingsPaneProviding`: Dedicated page in Droppy Settings with API key management and live connection testing.
- **Figma-Faithful Views**:
  - `CurrencyView`:
    - Screen A (Input): Charcoal `#414141` container, pale cyan search pill `#C4FBFF` with dark text, and 2 rows of quick currency shortcut chips (`USD`, `INR`, `EUR`, `GBP`, `AED`, `CAD`, `AUD`, `SGD`, `JPY`, `CHF`).
    - Screen B (Result): Source amount pill (`$ 67.87`) with swap/refresh rotation, rate equation (`$1 = ₹94.47`), historical trend graph card, and large cyan/teal converted amount card (`₹6411.37`).
  - `HistoricalGraphView`:
    - Native Swift Path/Canvas chart with coral/salmon curve (`#F87171`), area gradient fill, Y-axis levels, X-axis date stamps, and interactive hover tooltip (`96.34 Mon 5 Oct`).
  - `SettingsView`: Screen C with API key field, eye reveal toggle, info popover, default input currency picker, local currency picker, and graph toggle switch.
  - Continuous notch curvature clipping (`18pt` shelf, `26.5pt` island) conforming strictly to macOS hardware boundaries.

### 3. `SkyletHarness` & `SkyletTestsRunner`
- **`SkyletHarness`**: Embedded harness target running Droppy's real settings chrome for local testing and headless screenshot automation.
- **`SkyletTestsRunner`**: Lightweight executable test harness validating all 103 core unit tests locally.
