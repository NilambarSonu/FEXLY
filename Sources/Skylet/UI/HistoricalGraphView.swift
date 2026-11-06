//
//  HistoricalGraphView.swift
//  Skylet
//
//  Figma-faithful native historical exchange-rate graph with interactive range controls,
//  dynamic hover tooltip, and honest provider provenance.
//

import SwiftUI
import AppKit
import SkyletCore

private enum ChartDateFormatterCache {
    static let intradayTooltip: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm EEE d MMM"
        df.timeZone = TimeZone.current
        return df
    }()
    static let standardTooltip: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE d MMM"
        df.timeZone = TimeZone.current
        return df
    }()
    static let intradayAxis: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        df.timeZone = TimeZone.current
        return df
    }()
    static let standardAxis: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.timeZone = TimeZone.current
        return df
    }()
}

@MainActor
final class HistoricalGraphViewModel: ObservableObject {
    @Published var currentSeries: CurrencyHistorySeries?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hoveredPointIndex: Int? = nil

    func loadHistory(
        service: CurrencyHistoryService,
        from: CurrencyCode,
        to: CurrencyCode,
        range: CurrencyHistoryRange
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let series = try await service.getHistory(from: from, to: to, range: range)
            self.currentSeries = series
            self.isLoading = false
        } catch let err as LocalizedError {
            self.errorMessage = err.errorDescription ?? err.localizedDescription
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

public struct HistoricalGraphView: View {
    let service: CurrencyHistoryService
    let baseCurrency: CurrencyCode
    let quoteCurrency: CurrencyCode
    @Binding var selectedRange: CurrencyHistoryRange
    let isCompact: Bool

    @StateObject private var vm = HistoricalGraphViewModel()

    public init(
        service: CurrencyHistoryService,
        baseCurrency: CurrencyCode,
        quoteCurrency: CurrencyCode,
        selectedRange: Binding<CurrencyHistoryRange>,
        isCompact: Bool = false
    ) {
        self.service = service
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self._selectedRange = selectedRange
        self.isCompact = isCompact
    }

    public var body: some View {
        VStack(spacing: 4) {
            // Range Picker Tabs
            if !isCompact {
                rangePickerRow
            }

            // Chart Canvas or Status
            ZStack {
                if vm.isLoading && vm.currentSeries == nil {
                    loadingPlaceholder
                } else if let error = vm.errorMessage, vm.currentSeries == nil {
                    errorPlaceholder(error)
                } else if let series = vm.currentSeries, !series.points.isEmpty {
                    chartView(series)
                } else {
                    emptyPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(isCompact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
        .task(id: "\(baseCurrency.code)_\(quoteCurrency.code)_\(selectedRange.rawValue)") {
            await vm.loadHistory(
                service: service,
                from: baseCurrency,
                to: quoteCurrency,
                range: selectedRange
            )
        }
    }

    // MARK: - Range Picker Row

    private var rangePickerRow: some View {
        HStack(spacing: 3) {
            ForEach(CurrencyHistoryRange.allCases, id: \.self) { range in
                let isSelected = selectedRange == range
                Button {
                    guard selectedRange != range else { return }
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 8.5, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 2.5)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.22)
                                : Color.white.opacity(0.04)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Main Interactive Chart View

    private func chartView(_ series: CurrencyHistorySeries) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftMargin: CGFloat = isCompact ? 16 : 22
            let bottomMargin: CGFloat = isCompact ? 10 : 14
            let chartW = max(w - leftMargin - 6, 10)
            let chartH = max(h - bottomMargin - 4, 10)

            let points = series.points
            let rates = points.map { Double(truncating: $0.rate as NSNumber) }
            let minR = rates.min() ?? 0
            let maxR = rates.max() ?? 1
            let span = max(maxR - minR, 0.0001)

            // Normalize coordinate
            let coordinates: [CGPoint] = points.indices.map { idx in
                let fractionX = CGFloat(idx) / CGFloat(max(points.count - 1, 1))
                let x = leftMargin + fractionX * chartW
                let fractionY = CGFloat((rates[idx] - minR) / span)
                let y = chartH - fractionY * chartH + 2
                return CGPoint(x: x, y: y)
            }

            ZStack(alignment: .topLeading) {
                // Horizontal subtle gridlines & Y-axis labels
                if !isCompact {
                    yAxisLabelsAndGridlines(minRate: minR, maxRate: maxR, leftMargin: leftMargin, chartW: chartW, chartH: chartH)
                }

                // Area Fill Gradient
                areaPath(for: coordinates, bottomY: chartH)
                    .fill(
                        LinearGradient(
                            colors: [
                                SkyletTheme.chartLine.opacity(0.28),
                                SkyletTheme.chartLine.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Line Stroke
                linePath(for: coordinates)
                    .stroke(
                        SkyletTheme.chartLine,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )

                // Date Labels along bottom
                if !isCompact, points.count >= 2 {
                    xAxisDateLabels(points: points, leftMargin: leftMargin, chartW: chartW, y: chartH + 2)
                }

                // Interactive Hover Indicator & Tooltip
                if let hoverIdx = vm.hoveredPointIndex, hoverIdx < points.count, hoverIdx < coordinates.count {
                    let point = coordinates[hoverIdx]
                    let historyPt = points[hoverIdx]

                    // Vertical guide line (hit testing disabled to prevent hover jitter)
                    Path { p in
                        p.move(to: CGPoint(x: point.x, y: 0))
                        p.addLine(to: CGPoint(x: point.x, y: chartH))
                    }
                    .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .allowsHitTesting(false)

                    // Highlighted circle dot
                    Circle()
                        .fill(SkyletTheme.chartLine)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .position(point)
                        .allowsHitTesting(false)

                    // Tooltip badge
                    hoverTooltip(point: historyPt, coord: point, chartWidth: w)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let clampedX = min(max(location.x - leftMargin, 0), chartW)
                    let fraction = clampedX / chartW
                    let nearestIdx = min(max(Int(round(fraction * CGFloat(points.count - 1))), 0), points.count - 1)
                    if vm.hoveredPointIndex != nearestIdx {
                        vm.hoveredPointIndex = nearestIdx
                    }
                case .ended:
                    if vm.hoveredPointIndex != nil {
                        vm.hoveredPointIndex = nil
                    }
                }
            }
        }
    }

    // MARK: - Y-Axis Gridlines & Labels

    private func yAxisLabelsAndGridlines(
        minRate: Double,
        maxRate: Double,
        leftMargin: CGFloat,
        chartW: CGFloat,
        chartH: CGFloat
    ) -> some View {
        let stepCount = 3
        return ForEach(0...stepCount, id: \.self) { i in
            let fraction = CGFloat(i) / CGFloat(stepCount)
            let y = chartH - fraction * chartH + 2
            let rateValue = minRate + Double(fraction) * (maxRate - minRate)

            // Gridline
            Path { p in
                p.move(to: CGPoint(x: leftMargin, y: y))
                p.addLine(to: CGPoint(x: leftMargin + chartW, y: y))
            }
            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)

            // Axis Label
            Text(formatAxisNumber(rateValue))
                .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.40))
                .position(x: leftMargin / 2, y: y)
        }
    }

    // MARK: - X-Axis Date Labels

    private func xAxisDateLabels(
        points: [CurrencyHistoryPoint],
        leftMargin: CGFloat,
        chartW: CGFloat,
        y: CGFloat
    ) -> some View {
        guard let firstDate = points.first?.timestamp,
              let lastDate = points.last?.timestamp else {
            return AnyView(EmptyView())
        }
        let midDate = points[points.count / 2].timestamp

        let formatter = (selectedRange == .oneDay || selectedRange == .fiveDays)
            ? ChartDateFormatterCache.intradayAxis
            : ChartDateFormatterCache.standardAxis

        return AnyView(
            ZStack {
                Text(formatter.string(from: firstDate))
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .position(x: leftMargin + 10, y: y + 4)

                Text(formatter.string(from: midDate))
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .position(x: leftMargin + chartW / 2, y: y + 4)

                Text(formatter.string(from: lastDate))
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .position(x: leftMargin + chartW - 10, y: y + 4)
            }
            .allowsHitTesting(false)
        )
    }

    // MARK: - Hover Tooltip

    private func hoverTooltip(
        point: CurrencyHistoryPoint,
        coord: CGPoint,
        chartWidth: CGFloat
    ) -> some View {
        let df = (selectedRange == .oneDay || selectedRange == .fiveDays)
            ? ChartDateFormatterCache.intradayTooltip
            : ChartDateFormatterCache.standardTooltip
        let dateString = df.string(from: point.timestamp)
        let rateString = CurrencyFormatter.formatRateValue(point.rate)

        let tooltipWidth: CGFloat = 85
        let xPos = min(max(coord.x, tooltipWidth / 2 + 2), chartWidth - tooltipWidth / 2 - 2)

        return VStack(spacing: 1.5) {
            Text(rateString)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
            Text(dateString)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Color.black.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
        )
        .position(x: xPos, y: max(coord.y - 18, 12))
        .allowsHitTesting(false)
    }

    // MARK: - Paths

    private func linePath(for coordinates: [CGPoint]) -> Path {
        var path = Path()
        guard let first = coordinates.first else { return path }
        path.move(to: first)
        for i in 1..<coordinates.count {
            let prev = coordinates[i - 1]
            let curr = coordinates[i]
            let midX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
        return path
    }

    private func areaPath(for coordinates: [CGPoint], bottomY: CGFloat) -> Path {
        var path = linePath(for: coordinates)
        guard let first = coordinates.first, let last = coordinates.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: bottomY))
        path.addLine(to: CGPoint(x: first.x, y: bottomY))
        path.closeSubpath()
        return path
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        VStack(spacing: 4) {
            ProgressView()
                .controlSize(.mini)
            Text("Loading chart...")
                .font(.system(size: 8, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.40))
        }
    }

    private func errorPlaceholder(_ msg: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.35))
            Text(msg)
                .font(.system(size: 7.5, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
        }
    }

    private var emptyPlaceholder: some View {
        Text("No rate history available")
            .font(.system(size: 8, weight: .regular))
            .foregroundStyle(Color.white.opacity(0.40))
    }

    private func formatAxisNumber(_ val: Double) -> String {
        if val >= 100 {
            return String(format: "%.0f", val)
        } else if val >= 10 {
            return String(format: "%.1f", val)
        } else {
            return String(format: "%.2f", val)
        }
    }
}
