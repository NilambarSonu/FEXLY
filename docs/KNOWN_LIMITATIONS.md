# Known Limitations & Platform Boundaries

This document provides transparent engineering documentation regarding platform boundaries, edge cases, and design trade-offs in Skylet.

---

## 1. Global Text Selection Across Arbitrary Applications
- **Platform Constraint**: In macOS, detecting highlighted text across arbitrary third-party applications without explicit user action requires broad Accessibility (`AXUIElement`) permissions, active background polling, or simulated keyboard shortcuts (`⌘C`).
- **Skylet Design Decision**: Skylet intentionally avoids broad accessibility scraping or background clipboard polling to protect user privacy. Instead, Skylet provides a seamless explicit clipboard import: copy any price from any app, open Skylet on your shelf, and click **Paste**.

---

## 2. Real-Time Forex Quotas & Market Hours
- **Twelve Data Free Basic Tier**: Twelve Data provides 800 free API requests per day and up to 8 credits per minute. Skylet incorporates an automatic 5-minute pair cache to keep usage well below free plan limits during active sessions.
- **Weekend Market Closure**: Foreign exchange markets do not operate continuously 24/7 at standard retail liquidity. Over weekends (Friday evening through Sunday evening UTC) or central bank bank holidays, currency quotes are static. Skylet preserves the latest quote and honestly marks it as `DELAYED` for up to 72 hours, displaying the original quote timestamp rather than faking recent live ticks. Quotes exceeding 72 hours are marked `STALE`. On cache retrieval, `.delayed` and `.stale` provenance is strictly preserved and never falsely marked `.cached` or `.live`.
- **Keyless Fallback**: When an API key is not configured, Skylet falls back to open central-bank reference rates (`open.er-api.com` or `Frankfurter`), which update daily. Skylet transparently labels these as `DAILY REFERENCE`.

---

## 3. Unsupported Currencies
- Unofficial, defunct, or unlisted currencies not included in ISO 4217 or unsupported by the forex provider cannot be converted. In such cases, Skylet indicates that the currency pair is unsupported and displays a clear explanation.

---

## 4. Historical Data Quotas & Intraday Availability
- **Intraday Chart Provider Requirement**: Intraday historical charts (`1D` at 15-minute intervals and `5D` at 1-hour intervals) require a Twelve Data API key. Keyless central bank providers (such as Frankfurter / European Central Bank) publish daily closing reference points only, not intraday market ticks.
- **Honest Intraday Unavailable State**: When no Twelve Data key is configured, selecting `1D` or `5D` displays a clear explanatory message prompt rather than synthesizing fabricated ticks from daily averages.
- **Reference Range Coverage**: Daily reference ranges (`1M`, `1Y`, `5Y`, `Max`) work keylessly via Frankfurter for ECB-tracked currency pairs. Currencies outside the ECB's published basket require Twelve Data.
- **Quota Throttling**: Twelve Data Basic tier limits to 8 API requests/minute. Skylet's actor-based historical cache uses range-specific TTLs (5m for intraday, 12h for 1M/1Y, 24h for 5Y/Max) and concurrent request deduplication to prevent quota exhaustion.

---

## 5. Licensing & Display Rights
- Market quotes and historical series are queried directly client-side using the user's personal Twelve Data API key or public central-bank reference endpoints.
- Skylet acts strictly as a native local display client on macOS and does not redistribute, mirror, or commercialize proprietary financial data streams.
