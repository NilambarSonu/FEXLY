//
//  FrankfurterHistoryProvider.swift
//  SkyletCore
//
//  Keyless fallback historical provider using European Central Bank (ECB) reference rates.
//

import Foundation

public final class FrankfurterHistoryProvider: CurrencyHistoryProviding, @unchecked Sendable {
    public let providerName = "Frankfurter (ECB Daily Reference)"
    private let session: URLSession
    private let dateProvider: @Sendable () -> Date

    public init(
        session: URLSession = .shared,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.session = session
        self.dateProvider = dateProvider
    }

    public func fetchHistory(
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange
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
                providerName: providerName,
                interval: "1day",
                fetchTimestamp: now,
                freshness: .dailyReference
            )
        }

        // Frankfurter does not supply intraday (1D/5D) data
        if range.isIntraday {
            throw CurrencyHistoryError.intradayNotSupportedByReferenceProvider(range: range)
        }

        let now = dateProvider()
        let calendar = Calendar(identifier: .gregorian)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let endDateString = dateFormatter.string(from: now)
        let startDate: Date
        switch range {
        case .oneDay, .fiveDays:
            throw CurrencyHistoryError.intradayNotSupportedByReferenceProvider(range: range)
        case .oneMonth:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now.addingTimeInterval(-30 * 86400)
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-365 * 86400)
        case .fiveYears:
            startDate = calendar.date(byAdding: .year, value: -5, to: now) ?? now.addingTimeInterval(-5 * 365 * 86400)
        case .maximum:
            startDate = dateFormatter.date(from: "1999-01-04") ?? Date(timeIntervalSince1970: 915408000)
        }
        let startDateString = dateFormatter.string(from: startDate)

        guard let url = URL(string: "https://api.frankfurter.dev/v1/\(startDateString)..\(endDateString)?base=\(from.code)&symbols=\(to.code)") else {
            throw CurrencyHistoryError.malformedData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw CurrencyHistoryError.timeout
        } catch {
            throw CurrencyHistoryError.networkError(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                break
            case 404:
                throw CurrencyHistoryError.unsupportedCurrencyPair(from: from, to: to)
            default:
                throw CurrencyHistoryError.providerError("HTTP \(httpResponse.statusCode)")
            }
        }

        let decoded: FrankfurterTimeSeriesResponse
        do {
            decoded = try JSONDecoder().decode(FrankfurterTimeSeriesResponse.self, from: data)
        } catch {
            throw CurrencyHistoryError.malformedData
        }

        guard let ratesDict = decoded.rates, !ratesDict.isEmpty else {
            throw CurrencyHistoryError.emptySeries
        }

        var points: [CurrencyHistoryPoint] = []
        for (dateStr, symbolRates) in ratesDict {
            guard let date = dateFormatter.date(from: dateStr),
                  let doubleRate = symbolRates[to.code] else {
                continue
            }
            let decimalRate = Decimal(doubleRate)
            guard decimalRate > 0 else { continue }
            points.append(CurrencyHistoryPoint(timestamp: date, rate: decimalRate))
        }

        guard !points.isEmpty else {
            throw CurrencyHistoryError.emptySeries
        }

        points.sort { $0.timestamp < $1.timestamp }

        let latestTimestamp = points.last?.timestamp ?? now
        let quoteAge = now.timeIntervalSince(latestTimestamp)
        let freshness: RateFreshness = (quoteAge > 30 * 86400) ? .stale : .dailyReference

        return CurrencyHistorySeries(
            baseCurrency: from,
            quoteCurrency: to,
            range: range,
            points: points,
            providerName: providerName,
            interval: "1day",
            fetchTimestamp: now,
            quoteTimestamp: latestTimestamp,
            freshness: freshness,
            isFromCache: false
        )
    }
}

// MARK: - Frankfurter Decodable Models

private struct FrankfurterTimeSeriesResponse: Decodable {
    let amount: Double?
    let base: String?
    let start_date: String?
    let end_date: String?
    let rates: [String: [String: Double]]?
}
