//
//  TwelveDataHistoryProvider.swift
//  SkyletCore
//
//  Primary real-time historical series provider using Twelve Data Forex API.
//

import Foundation

public final class TwelveDataHistoryProvider: CurrencyHistoryProviding, @unchecked Sendable {
    public let providerName = "Twelve Data"
    private let session: URLSession
    private let apiKeyProvider: @Sendable () -> String?
    private let dateProvider: @Sendable () -> Date

    public init(
        session: URLSession = .shared,
        apiKeyProvider: @escaping @Sendable () -> String?,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
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
                interval: range.twelveDataInterval,
                fetchTimestamp: now,
                freshness: .live
            )
        }

        guard let rawKey = apiKeyProvider(),
              !rawKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CurrencyHistoryError.missingAPIKey
        }
        let apiKey = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let symbol = "\(from.code)/\(to.code)"
        var components = URLComponents(string: "https://api.twelvedata.com/time_series")
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "interval", value: range.twelveDataInterval),
            URLQueryItem(name: "outputsize", value: String(range.twelveDataOutputSize))
        ]

        guard let url = components?.url else {
            throw CurrencyHistoryError.malformedData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("apikey \(apiKey)", forHTTPHeaderField: "Authorization")
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
            case 401:
                throw CurrencyHistoryError.invalidAPIKey
            case 429:
                throw CurrencyHistoryError.rateLimitExceeded
            case 404:
                throw CurrencyHistoryError.unsupportedCurrencyPair(from: from, to: to)
            default:
                throw CurrencyHistoryError.providerError("HTTP \(httpResponse.statusCode)")
            }
        }

        let decoded: TwelveDataTimeSeriesResponse
        do {
            decoded = try JSONDecoder().decode(TwelveDataTimeSeriesResponse.self, from: data)
        } catch {
            throw CurrencyHistoryError.malformedData
        }

        // Check for provider-level error responses (sometimes returned with HTTP 200)
        if let status = decoded.status, status.lowercased() == "error" {
            let code = decoded.code ?? 0
            let message = decoded.message ?? "Unknown error"
            if code == 401 || message.localizedCaseInsensitiveContains("api key") {
                throw CurrencyHistoryError.invalidAPIKey
            } else if code == 429 || message.localizedCaseInsensitiveContains("limit") {
                throw CurrencyHistoryError.rateLimitExceeded
            } else if code == 404 || message.localizedCaseInsensitiveContains("not found") {
                throw CurrencyHistoryError.unsupportedCurrencyPair(from: from, to: to)
            } else {
                throw CurrencyHistoryError.providerError(message)
            }
        }

        guard let values = decoded.values, !values.isEmpty else {
            throw CurrencyHistoryError.emptySeries
        }

        let dateFormatterWithTime = DateFormatter()
        dateFormatterWithTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatterWithTime.timeZone = TimeZone(secondsFromGMT: 0)

        let dateFormatterDateOnly = DateFormatter()
        dateFormatterDateOnly.dateFormat = "yyyy-MM-dd"
        dateFormatterDateOnly.timeZone = TimeZone(secondsFromGMT: 0)

        var points: [CurrencyHistoryPoint] = []
        var seenDates = Set<Date>()

        for val in values {
            guard let dtString = val.datetime,
                  let closeString = val.close,
                  let rateDecimal = Decimal(string: closeString),
                  rateDecimal > 0 else {
                continue
            }

            guard let date = dateFormatterWithTime.date(from: dtString) ?? dateFormatterDateOnly.date(from: dtString) else {
                continue
            }

            // Deduplicate same timestamp if returned
            if seenDates.insert(date).inserted {
                points.append(CurrencyHistoryPoint(timestamp: date, rate: rateDecimal))
            }
        }

        guard !points.isEmpty else {
            throw CurrencyHistoryError.emptySeries
        }

        // Twelve Data returns newest-first; sort chronological ascending (oldest -> newest)
        points.sort { $0.timestamp < $1.timestamp }

        let now = dateProvider()
        let latestTimestamp = points.last?.timestamp ?? now
        let age = now.timeIntervalSince(latestTimestamp)

        let freshness: RateFreshness
        if age <= 15 * 60 {
            freshness = .live
        } else if age <= 72 * 3600 {
            freshness = .delayed
        } else {
            freshness = .stale
        }

        return CurrencyHistorySeries(
            baseCurrency: from,
            quoteCurrency: to,
            range: range,
            points: points,
            providerName: providerName,
            interval: decoded.meta?.interval ?? range.twelveDataInterval,
            fetchTimestamp: now,
            quoteTimestamp: latestTimestamp,
            freshness: freshness,
            isFromCache: false
        )
    }
}

// MARK: - Twelve Data Decodable Models

private struct TwelveDataTimeSeriesResponse: Decodable {
    let meta: TwelveDataMeta?
    let values: [TwelveDataValue]?
    let status: String?
    let code: Int?
    let message: String?
}

private struct TwelveDataMeta: Decodable {
    let symbol: String?
    let interval: String?
    let currency_base: String?
    let currency_quote: String?
}

private struct TwelveDataValue: Decodable {
    let datetime: String?
    let open: String?
    let high: String?
    let low: String?
    let close: String?
}

