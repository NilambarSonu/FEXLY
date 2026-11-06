//
//  CurrencyHistoryService.swift
//  SkyletCore
//
//  Service coordinating historical Forex providers, reference fallbacks,
//  request deduplication, and cache lifecycle.
//

import Foundation

public actor CurrencyHistoryService {
    private let cache: CurrencyHistoryCache
    private let twelveDataProvider: CurrencyHistoryProviding?
    private let fallbackProvider: CurrencyHistoryProviding?
    private let dateProvider: @Sendable () -> Date
    private var inFlightTasks: [String: Task<CurrencyHistorySeries, Error>] = [:]

    public init(
        cache: CurrencyHistoryCache = CurrencyHistoryCache(),
        twelveDataProvider: CurrencyHistoryProviding? = nil,
        fallbackProvider: CurrencyHistoryProviding? = nil,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.cache = cache
        self.twelveDataProvider = twelveDataProvider
        self.fallbackProvider = fallbackProvider
        self.dateProvider = dateProvider
    }

    /// Fetches historical rate series for the specified pair and range.
    /// Deduplicates concurrent identical requests and checks cache first.
    public func getHistory(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange,
        forceRefresh: Bool = false
    ) async throws -> CurrencyHistorySeries {
        // Identity conversion
        if from == to {
            let now = dateProvider()
            let flatPoint = CurrencyHistoryPoint(timestamp: now, rate: Decimal(1))
            return CurrencyHistorySeries(
                baseCurrency: from,
                quoteCurrency: to,
                range: range,
                points: [flatPoint],
                providerName: "Local (Same Currency)",
                interval: range.twelveDataInterval,
                fetchTimestamp: now,
                freshness: .live
            )
        }

        let key = CurrencyHistoryCache.cacheKey(from: from, to: to, range: range)

        // Return from cache if fresh and not forcing refresh
        if !forceRefresh, let cached = await cache.get(from: from, to: to, range: range), !cached.isStale {
            return cached.series
        }

        // Deduplicate in-flight requests
        if let existingTask = inFlightTasks[key] {
            return try await existingTask.value
        }

        let task = Task<CurrencyHistorySeries, Error> { [weak self] in
            guard let self else { throw CurrencyHistoryError.malformedData }
            return try await self.executeFetch(from: from, to: to, range: range)
        }

        inFlightTasks[key] = task
        defer { inFlightTasks.removeValue(forKey: key) }

        do {
            let series = try await task.value
            await cache.set(series)
            return series
        } catch {
            // Check if any stale cached series is available to gracefully display
            if let staleCached = await cache.get(from: from, to: to, range: range) {
                return staleCached.series
            }
            throw error
        }
    }

    private func executeFetch(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange
    ) async throws -> CurrencyHistorySeries {
        var lastError: Error?

        // 1. Try Twelve Data primary provider if available
        if let primary = twelveDataProvider {
            do {
                return try await primary.fetchHistory(from: from, to: to, range: range)
            } catch {
                lastError = error
                // If primary was rejected due to missing/invalid key or rate limit, fall back to reference
            }
        }

        // 2. If range is intraday and primary failed/unavailable, intraday cannot fall back to daily reference
        if range.isIntraday {
            if let typedError = lastError as? CurrencyHistoryError {
                throw typedError
            } else if twelveDataProvider == nil {
                throw CurrencyHistoryError.missingAPIKey
            } else {
                throw lastError ?? CurrencyHistoryError.intradayNotSupportedByReferenceProvider(range: range)
            }
        }

        // 3. Fallback to Frankfurter (ECB daily reference) for daily/weekly/monthly ranges
        if let fallback = fallbackProvider {
            do {
                return try await fallback.fetchHistory(from: from, to: to, range: range)
            } catch {
                throw error
            }
        }

        throw lastError ?? CurrencyHistoryError.unsupportedCurrencyPair(from: from, to: to)
    }

    public func clearCache() async {
        await cache.clear()
    }
}
