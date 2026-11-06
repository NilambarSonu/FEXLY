//
//  CurrencyHistoryRange.swift
//  SkyletCore
//
//  Supported historical chart ranges and provider mapping for Skylet.
//

import Foundation

/// Supported historical chart ranges in Skylet UI.
public enum CurrencyHistoryRange: String, CaseIterable, Codable, Sendable {
    case oneDay = "1D"
    case fiveDays = "5D"
    case oneMonth = "1M"
    case oneYear = "1Y"
    case fiveYears = "5Y"
    case maximum = "Max"

    /// Suggested Twelve Data interval query parameter.
    public var twelveDataInterval: String {
        switch self {
        case .oneDay: return "15min"
        case .fiveDays: return "1h"
        case .oneMonth: return "1day"
        case .oneYear: return "1day"
        case .fiveYears: return "1week"
        case .maximum: return "1month"
        }
    }

    /// Suggested outputsize limit for Twelve Data requests.
    public var twelveDataOutputSize: Int {
        switch self {
        case .oneDay: return 96
        case .fiveDays: return 120
        case .oneMonth: return 32
        case .oneYear: return 260
        case .fiveYears: return 260
        case .maximum: return 120
        }
    }

    /// Cache lifetime before revalidating against providers.
    public var cacheTTL: TimeInterval {
        switch self {
        case .oneDay: return 5 * 60       // 5 minutes
        case .fiveDays: return 5 * 60      // 5 minutes
        case .oneMonth: return 12 * 3600   // 12 hours
        case .oneYear: return 12 * 3600    // 12 hours
        case .fiveYears: return 24 * 3600  // 24 hours
        case .maximum: return 24 * 3600    // 24 hours
        }
    }

    /// Whether this range requires intraday tick / hourly intervals
    /// (which daily reference providers like Frankfurter ECB cannot supply).
    public var isIntraday: Bool {
        switch self {
        case .oneDay, .fiveDays:
            return true
        case .oneMonth, .oneYear, .fiveYears, .maximum:
            return false
        }
    }
}

