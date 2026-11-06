//
//  CurrencyHistoryModels.swift
//  SkyletCore
//
//  Domain models for historical foreign exchange series and data points.
//

import Foundation

/// A single timestamped rate point in a historical exchange rate series.
public struct CurrencyHistoryPoint: Codable, Equatable, Sendable, Identifiable {
    public var id: Date { timestamp }
    public let timestamp: Date
    public let rate: Decimal

    public init(timestamp: Date, rate: Decimal) {
        self.timestamp = timestamp
        self.rate = rate
    }
}

/// Errors thrown by the currency history subsystem.
public enum CurrencyHistoryError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case rateLimitExceeded
    case unsupportedCurrencyPair(from: CurrencyCode, to: CurrencyCode)
    case intradayNotSupportedByReferenceProvider(range: CurrencyHistoryRange)
    case malformedData
    case emptySeries
    case timeout
    case networkError(String)
    case providerRateNonPositive(Decimal)
    case providerError(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Twelve Data API key is required for historical rates."
        case .invalidAPIKey:
            return "Twelve Data API key was rejected as invalid."
        case .rateLimitExceeded:
            return "Twelve Data API rate limit reached. Please wait a moment."
        case .unsupportedCurrencyPair(let from, let to):
            return "Historical rate data for \(from.code)/\(to.code) is not supported."
        case .intradayNotSupportedByReferenceProvider(let range):
            return "\(range.rawValue) chart requires intraday data. Configure a Twelve Data API key in Settings to view intraday charts."
        case .malformedData:
            return "Historical rate provider returned invalid or corrupted data."
        case .emptySeries:
            return "No historical rate points were returned for this range."
        case .timeout:
            return "Historical rate request timed out."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .providerRateNonPositive:
            return "Provider returned a non-positive historical rate."
        case .providerError(let msg):
            return "Provider error: \(msg)"
        }
    }
}

/// A complete historical series for a currency pair and range.
public struct CurrencyHistorySeries: Codable, Equatable, Sendable {
    public let baseCurrency: CurrencyCode
    public let quoteCurrency: CurrencyCode
    public let range: CurrencyHistoryRange
    public let points: [CurrencyHistoryPoint]
    public let providerName: String
    public let interval: String
    public let fetchTimestamp: Date
    public let quoteTimestamp: Date?
    public let freshness: RateFreshness
    public let isFromCache: Bool

    public init(
        baseCurrency: CurrencyCode,
        quoteCurrency: CurrencyCode,
        range: CurrencyHistoryRange,
        points: [CurrencyHistoryPoint],
        providerName: String,
        interval: String,
        fetchTimestamp: Date,
        quoteTimestamp: Date? = nil,
        freshness: RateFreshness = .live,
        isFromCache: Bool = false
    ) {
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self.range = range
        self.points = points
        self.providerName = providerName
        self.interval = interval
        self.fetchTimestamp = fetchTimestamp
        self.quoteTimestamp = quoteTimestamp
        self.freshness = freshness
        self.isFromCache = isFromCache
    }

    /// Lowest rate across the series.
    public var minRate: Decimal? {
        points.map(\.rate).min()
    }

    /// Highest rate across the series.
    public var maxRate: Decimal? {
        points.map(\.rate).max()
    }

    /// First (earliest) rate in the chronological series.
    public var startRate: Decimal? {
        points.first?.rate
    }

    /// Latest (most recent) rate in the chronological series.
    public var endRate: Decimal? {
        points.last?.rate
    }

    /// Percentage change from start to end of series.
    public var percentageChange: Decimal? {
        guard let start = startRate, let end = endRate, start > 0 else { return nil }
        return ((end - start) / start) * 100
    }
}

