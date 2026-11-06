//
//  CurrencyView.swift
//  Skylet
//
//  Figma-faithful currency conversion interface supporting input state (Screen A)
//  and conversion result state (Screen B) with historical FX charts.
//

import SwiftUI
import AppKit
import DroppyKit
import SkyletCore

public struct CurrencyView: View {
    @ObservedObject var droplet: SkyletDroplet
    let isCompact: Bool

    @State private var inputText: String = ""
    @State private var sourceCurrency: CurrencyCode = .usd
    @State private var targetCurrency: CurrencyCode = .inr
    @State private var conversionResult: CurrencyConversionResult?
    @State private var isShowingResult: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isEditingResultAmount: Bool = false
    @State private var isRotating: Double = 0
    @State private var copiedConfirmation: Bool = false
    @FocusState private var isSearchFocused: Bool

    // Quick Currency Shortcuts
    private let topShortcuts: [CurrencyCode] = [.usd, .inr, .eur, .gbp, .aed]
    private let bottomShortcuts: [CurrencyCode] = [.cad, .aud, .sgd, .jpy, .chf]

    public init(droplet: SkyletDroplet, isCompact: Bool) {
        self.droplet = droplet
        self.isCompact = isCompact
    }

    public var body: some View {
        VStack(spacing: 8) {
            if isShowingResult && conversionResult != nil {
                resultStateView
            } else {
                inputStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            sourceCurrency = droplet.defaultInputCurrency
            targetCurrency = droplet.localTargetCurrency
            if let existing = droplet.latestConversion {
                self.conversionResult = existing
                self.isShowingResult = true
            }
        }
    }

    // MARK: - Screen A: Input State View

    private var inputStateView: some View {
        VStack(spacing: 10) {
            // Header: Settings Icon & API Active Status
            HStack {
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.selectedMode = .settings
                    }
                } label: {
                    SkyletIcon.SettingsShape()
                        .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.plain)
                .help("Open Skylet Settings")

                Spacer()

                providerStatusBadge
            }
            .padding(.horizontal, 4)

            // Large Pale Cyan Rounded Search / Input Pill
            HStack(spacing: 8) {
                TextField("67.87 in USD", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkyletTheme.darkInputText)
                    .focused($isSearchFocused)
                    .onSubmit {
                        submitInput()
                    }

                Button {
                    submitInput()
                } label: {
                    SkyletIcon.SearchShape()
                        .stroke(SkyletTheme.darkInputText, lineWidth: 2)
                        .frame(width: 17, height: 17)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(SkyletTheme.inputAccent)
            .clipShape(Capsule())

            // Quick Currency Shortcut Chips
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(topShortcuts, id: \.self) { code in
                        quickCurrencyChip(code: code)
                    }
                }
                HStack(spacing: 6) {
                    ForEach(bottomShortcuts, id: \.self) { code in
                        quickCurrencyChip(code: code)
                    }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 9.5))
                    .foregroundStyle(SkyletTheme.statusError)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    // MARK: - Screen B: Result State View

    private var resultStateView: some View {
        VStack(spacing: 8) {
            // Upper Row: Amount Pill (Left) & Rate Formula / Status (Right)
            HStack(alignment: .center, spacing: 10) {
                // Source Amount Pill in Pale Cyan
                HStack(spacing: 6) {
                    let sourceFormatted = CurrencyFormatter.format(
                        amount: conversionResult?.sourceAmount ?? 0,
                        currency: conversionResult?.sourceCurrency ?? sourceCurrency
                    )

                    Button {
                        withAnimation(SkyletTheme.quickAnimation) {
                            self.inputText = "\(conversionResult?.sourceAmount ?? 0) \(conversionResult?.sourceCurrency.rawValue ?? "")"
                            self.isShowingResult = false
                        }
                    } label: {
                        Text(sourceFormatted)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(SkyletTheme.darkInputText)
                    }
                    .buttonStyle(.plain)
                    .help("Click to edit amount")

                    Spacer(minLength: 4)

                    // Rotate / Swap Button
                    Button {
                        swapCurrencies()
                    } label: {
                        SkyletIcon.RotateShape()
                            .stroke(SkyletTheme.darkInputText, lineWidth: 1.8)
                            .frame(width: 14, height: 14)
                            .rotationEffect(.degrees(isRotating))
                    }
                    .buttonStyle(.plain)
                    .help("Swap currency direction")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(SkyletTheme.inputAccent)
                .clipShape(Capsule())
                .frame(maxWidth: isCompact ? .infinity : 155)

                Spacer(minLength: 0)

                // Rate Formula & Status Badge
                VStack(alignment: .trailing, spacing: 2) {
                    providerStatusBadge

                    if let res = conversionResult {
                        let sourceCode = res.sourceCurrency.rawValue
                        let targetSymbol = CurrencyMetadata.symbol(for: res.targetCurrency)
                        let formattedRate = CurrencyFormatter.formatRateValue(res.rate)
                        Text("1 \(sourceCode) = \(targetSymbol)\(formattedRate)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.90))
                    }
                }
            }
            .padding(.horizontal, 2)

            // Lower Section: Historical Graph Card (Left) & Converted Amount (Right)
            if isCompact {
                // Compact / Paired Mode: Stacked layout
                convertedAmountCard
                    .frame(height: 52)
                if droplet.isGraphEnabled {
                    HistoricalGraphView(
                        service: droplet.historyService,
                        baseCurrency: conversionResult?.sourceCurrency ?? sourceCurrency,
                        quoteCurrency: conversionResult?.targetCurrency ?? targetCurrency,
                        selectedRange: $droplet.selectedGraphRange,
                        isCompact: true
                    )
                    .frame(height: 55)
                }
            } else {
                // Solo Mode: Side-by-Side layout exactly matching Figma Screenshot
                HStack(spacing: 8) {
                    if droplet.isGraphEnabled {
                        HistoricalGraphView(
                            service: droplet.historyService,
                            baseCurrency: conversionResult?.sourceCurrency ?? sourceCurrency,
                            quoteCurrency: conversionResult?.targetCurrency ?? targetCurrency,
                            selectedRange: $droplet.selectedGraphRange,
                            isCompact: false
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    convertedAmountCard
                        .frame(width: droplet.isGraphEnabled ? 160 : .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    // MARK: - Large Converted Amount Card

    private var convertedAmountCard: some View {
        let targetFormatted = CurrencyFormatter.format(
            amount: conversionResult?.targetAmount ?? 0,
            currency: conversionResult?.targetCurrency ?? targetCurrency
        )

        return Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(targetFormatted, forType: .string)
            withAnimation(SkyletTheme.quickAnimation) {
                copiedConfirmation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(SkyletTheme.quickAnimation) {
                    copiedConfirmation = false
                }
            }
        } label: {
            ZStack {
                // Cyan / Teal Gradient Background matching Figma
                LinearGradient(
                    colors: [
                        Color(red: 0x5E/255.0, green: 0xEA/255.0, blue: 0xD4/255.0),
                        Color(red: 0x2D/255.0, green: 0xD4/255.0, blue: 0xBF/255.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 2) {
                    if copiedConfirmation {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Copied")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0x06/255.0, green: 0x4E/255.0, blue: 0x3B/255.0))
                    } else {
                        Text(targetFormatted)
                            .font(.system(size: isCompact ? 18 : 22, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 0x04/255.0, green: 0x2F/255.0, blue: 0x2E/255.0))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .help("Click to copy converted amount")
    }

    // MARK: - Quick Currency Chip

    private func quickCurrencyChip(code: CurrencyCode) -> some View {
        let isSelected = (code == sourceCurrency || code == targetCurrency)

        return Button {
            // If input is empty, set source currency
            if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sourceCurrency = code
                inputText = "100 \(code.rawValue)"
            } else {
                // If input has numbers, append or switch currency
                let parsed = CurrencyParser.parse(inputText)
                switch parsed {
                case .amountOnly(let amt, _):
                    sourceCurrency = code
                    inputText = "\(amt) \(code.rawValue)"
                case .unambiguous(let amt, _, _):
                    sourceCurrency = code
                    inputText = "\(amt) \(code.rawValue)"
                default:
                    inputText = "\(inputText) in \(code.rawValue)"
                }
            }
            submitInput()
        } label: {
            Text(code.rawValue)
                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.black : Color.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(isSelected ? Color.white : SkyletTheme.lightControls)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Provider Status Badge

    private var providerStatusBadge: some View {
        let hasKey = (droplet.keychain.get(key: "twelvedata_api_key") != nil)
        let isLive = conversionResult?.freshness == .live

        return HStack(spacing: 4) {
            Circle()
                .fill(isLive ? SkyletTheme.activeStatus : (hasKey ? SkyletTheme.statusDelayed : Color.white.opacity(0.50)))
                .frame(width: 5, height: 5)
            Text(isLive ? "• API Active" : (hasKey ? "• Delayed" : "• Daily Reference"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isLive ? SkyletTheme.activeStatus : SkyletTheme.secondaryText)
        }
    }

    // MARK: - Actions

    private func submitInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let parsed = CurrencyParser.parse(trimmed)
        let amount: Decimal
        var fromCode = sourceCurrency
        var toCode = targetCurrency

        switch parsed {
        case .empty:
            return
        case .invalidAmount:
            errorMessage = "Please enter a valid amount and currency."
            return
        case .multipleAmountsFound:
            errorMessage = "Multiple amounts found. Please enter a single amount."
            return
        case .amountOnly(let amt, _):
            amount = amt
            fromCode = droplet.defaultInputCurrency
            toCode = droplet.localTargetCurrency
        case .unambiguous(let amt, let curr, _):
            amount = amt
            fromCode = curr
            toCode = (curr == droplet.localTargetCurrency) ? droplet.defaultInputCurrency : droplet.localTargetCurrency
        case .ambiguous(let amt, _, let candidates, _):
            amount = amt
            fromCode = candidates.first ?? droplet.defaultInputCurrency
            toCode = (fromCode == droplet.localTargetCurrency) ? droplet.defaultInputCurrency : droplet.localTargetCurrency
        case .unknownCurrency(let amt, _, _):
            amount = amt
            fromCode = droplet.defaultInputCurrency
            toCode = droplet.localTargetCurrency
        @unknown default:
            errorMessage = "Unable to parse input."
            return
        }

        sourceCurrency = fromCode
        targetCurrency = toCode
        executeConversion(amount: amount, source: fromCode, target: toCode)
    }

    private func executeConversion(amount: Decimal, source: CurrencyCode, target: CurrencyCode) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await droplet.rateService.convert(
                    amount: amount,
                    from: source,
                    to: target
                )
                await MainActor.run {
                    self.conversionResult = result
                    self.droplet.updateLatestConversion(result)
                    self.isShowingResult = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func swapCurrencies() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isRotating += 180
        }
        let temp = sourceCurrency
        sourceCurrency = targetCurrency
        targetCurrency = temp

        if let res = conversionResult {
            executeConversion(amount: res.sourceAmount, source: sourceCurrency, target: targetCurrency)
        }
    }
}
