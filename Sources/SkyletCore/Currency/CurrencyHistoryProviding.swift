//
//  CurrencyHistoryProviding.swift
//  SkyletCore
//
//  Protocol defining historical exchange rate providers.
//

import Foundation

/// Protocol defining the interface for historical exchange rate providers.
public protocol CurrencyHistoryProviding: Sendable {
    var providerName: String { get }

    func fetchHistory(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange
    ) async throws -> CurrencyHistorySeries
}

