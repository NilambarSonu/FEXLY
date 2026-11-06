//
//  CurrencyHistoryCache.swift
//  SkyletCore
//
//  Actor-based disk and memory cache for historical exchange-rate series.
//

import Foundation

public actor CurrencyHistoryCache {
    private var memoryEntries: [String: CurrencyHistorySeries] = [:]
    private let fileURL: URL?
    private let dateProvider: @Sendable () -> Date

    public init(
        persistToDisk: Bool = true,
        fileURL: URL? = nil,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.dateProvider = dateProvider
        if !persistToDisk {
            self.fileURL = nil
        } else if let fileURL {
            self.fileURL = fileURL
        } else {
            let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            let appDir = cachesDir?.appendingPathComponent("Skylet", isDirectory: true)
            if let appDir {
                try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
                self.fileURL = appDir.appendingPathComponent("history_series_cache.json")
            } else {
                self.fileURL = nil
            }
        }
        if let fileURL = self.fileURL {
            self.memoryEntries = Self.loadEntries(from: fileURL)
        }
    }

    public static func cacheKey(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange
    ) -> String {
        "\(from.code)_\(to.code)_\(range.rawValue)"
    }

    public func get(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange,
        asOf date: Date? = nil
    ) -> (series: CurrencyHistorySeries, isStale: Bool)? {
        let key = Self.cacheKey(from: from, to: to, range: range)
        guard let entry = memoryEntries[key] else { return nil }

        let now = date ?? dateProvider()
        let fetchAge = now.timeIntervalSince(entry.fetchTimestamp)
        let isExpired = fetchAge > range.cacheTTL

        let derivedFreshness: RateFreshness
        if isExpired {
            derivedFreshness = .stale
        } else if entry.freshness == .dailyReference {
            derivedFreshness = .dailyReference
        } else if entry.freshness == .delayed {
            derivedFreshness = .delayed
        } else {
            derivedFreshness = .cached
        }

        let presentationSeries = CurrencyHistorySeries(
            baseCurrency: entry.baseCurrency,
            quoteCurrency: entry.quoteCurrency,
            range: entry.range,
            points: entry.points,
            providerName: entry.providerName,
            interval: entry.interval,
            fetchTimestamp: entry.fetchTimestamp,
            quoteTimestamp: entry.quoteTimestamp,
            freshness: derivedFreshness,
            isFromCache: true
        )

        return (presentationSeries, isExpired)
    }

    public func set(_ series: CurrencyHistorySeries) {
        let key = Self.cacheKey(from: series.baseCurrency, to: series.quoteCurrency, range: series.range)
        memoryEntries[key] = series
        saveToDisk()
    }

    public func clear() {
        memoryEntries.removeAll()
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func loadEntries(from fileURL: URL) -> [String: CurrencyHistorySeries] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: CurrencyHistorySeries].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveToDisk() {
        guard let fileURL else { return }
        if let data = try? JSONEncoder().encode(memoryEntries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
