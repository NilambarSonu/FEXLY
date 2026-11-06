//
//  CurrencyView.swift
//  Skylet
//
//  Apple Liquid Glass currency conversion interface supporting input state (Screen A)
//  and editable conversion result state (Screen B) with historical FX charts.
//

import SwiftUI
import AppKit
import DroppyKit
import SkyletCore

public struct CurrencyView: View {
    @ObservedObject var droplet: SkyletDroplet
    let isCompact: Bool

    @State private var inputText: String = ""
    @State private var editableAmountText: String = "100.00"
    @State private var sourceCurrency: CurrencyCode = .usd
    @State private var targetCurrency: CurrencyCode = .inr
    @State private var conversionResult: CurrencyConversionResult?
    @State private var isShowingResult: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var refreshSpinAngle: Double = 0
    @State private var copiedConfirmation: Bool = false
    @State private var isTargetedDefault: Bool = false
    @State private var isTargetedLocal: Bool = false
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isAmountFocused: Bool

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
                self.sourceCurrency = existing.sourceCurrency
                self.targetCurrency = existing.targetCurrency
                self.editableAmountText = "\(existing.sourceAmount)"
                self.isShowingResult = true
            }
        }
    }

    // MARK: - Dynamic Shortcut Currency Layout
    // Row 1: Card 0 = Default Currency, Card 1 = Local Currency, followed by top world currencies
    // Row 2: Remaining popular currencies
    private var shortcutRows: ([CurrencyCode], [CurrencyCode]) {
        let def = droplet.defaultInputCurrency
        let loc = droplet.localTargetCurrency

        let pool: [CurrencyCode] = [.usd, .inr, .eur, .gbp, .aed, .cad, .aud, .sgd, .jpy, .chf]
        var remaining = pool.filter { $0 != def && $0 != loc }

        var row1: [CurrencyCode] = [def, loc]
        while row1.count < 5 && !remaining.isEmpty {
            row1.append(remaining.removeFirst())
        }

        var row2: [CurrencyCode] = []
        while row2.count < 5 && !remaining.isEmpty {
            row2.append(remaining.removeFirst())
        }
        for c in CurrencyCode.allCases where !row1.contains(c) && !row2.contains(c) && row2.count < 5 {
            row2.append(c)
        }

        return (row1, row2)
    }

    // MARK: - Screen A: Input State View

    private var inputStateView: some View {
        VStack(spacing: 8) {
            // Header: Settings Icon & API Active Status
            HStack {
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.selectedMode = .settings
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.10))
                                .background(.ultraThinMaterial)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Open Skylet Settings")

                Spacer()

                providerStatusBadge
            }
            .padding(.horizontal, 2)

            // Large Apple Liquid Glass Search Capsule
            HStack(spacing: 8) {
                TextField("e.g. 100 USD or €49.99", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                    .focused($isSearchFocused)
                    .onSubmit {
                        submitInput()
                    }

                Button {
                    submitInput()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSearchFocused ? Color.white : Color.white.opacity(0.65))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(isSearchFocused ? 0.14 : 0.09))
                    .background(.ultraThinMaterial)
            )
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSearchFocused ? SkyletTheme.skyBlue.opacity(0.60) : Color.white.opacity(0.16), lineWidth: 0.5)
            )

            // Quick Currency Shortcut Chips (Draggable & Drop Targets)
            let (row1, row2) = shortcutRows
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(Array(row1.enumerated()), id: \.element) { index, code in
                        quickCurrencyChip(code: code, isFirstRowLead: (index == 0), isFirstRowSecond: (index == 1))
                    }
                }
                HStack(spacing: 6) {
                    ForEach(row2, id: \.self) { code in
                        quickCurrencyChip(code: code, isFirstRowLead: false, isFirstRowSecond: false)
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
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    // MARK: - Screen B: Result State View

    private var resultStateView: some View {
        VStack(spacing: 8) {
            resultHeaderRow
            resultLowerContent
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    private var resultHeaderRow: some View {
        HStack(alignment: .center, spacing: 8) {
            headerBackButton
            sourceAmountCapsule
            Spacer(minLength: 0)
            headerRateAndStatus
        }
        .padding(.horizontal, 2)
    }

    private var headerBackButton: some View {
        Button {
            withAnimation(SkyletTheme.quickAnimation) {
                isShowingResult = false
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.90))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .background(.ultraThinMaterial)
                )
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Back to Currency Input")
    }

    private var sourceAmountCapsule: some View {
        HStack(spacing: 6) {
            sourceCurrencyDropdown
            editableAmountField
            refreshSpinButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
                .background(.ultraThinMaterial)
        )
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        )
    }

    private var sourceCurrencyDropdown: some View {
        Menu {
            ForEach(CurrencyCode.allCases, id: \.self) { c in
                Button {
                    sourceCurrency = c
                    recalculateWithCurrentInput()
                } label: {
                    HStack {
                        Text("\(CurrencyMetadata.symbol(for: c))  \(c.rawValue) — \(CurrencyMetadata.name(for: c))")
                        if sourceCurrency == c { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(CurrencyMetadata.symbol(for: sourceCurrency))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.60))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .help("Change Source Currency")
    }

    private var editableAmountField: some View {
        TextField("Amount", text: $editableAmountText)
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
            .focused($isAmountFocused)
            .frame(minWidth: 48)
            .onSubmit {
                recalculateWithCurrentInput()
            }
    }

    private var refreshSpinButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                refreshSpinAngle += 360
            }
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            recalculateWithCurrentInput()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .rotationEffect(.degrees(refreshSpinAngle))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Refresh live exchange rate")
    }

    private var headerRateAndStatus: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                providerStatusBadge

                if let res = conversionResult {
                    let sourceCode = res.sourceCurrency.rawValue
                    let targetSymbol = CurrencyMetadata.symbol(for: res.targetCurrency)
                    let formattedRate = CurrencyFormatter.formatRateValue(res.rate)
                    Text("1 \(sourceCode) = \(targetSymbol)\(formattedRate)")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }

            // Pin Icon (Keep shelf awake until cancelled)
            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    droplet.isPinned.toggle()
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
            } label: {
                Image(systemName: droplet.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(droplet.isPinned ? SkyletTheme.skyBlue : Color.white.opacity(0.65))
                    .rotationEffect(.degrees(droplet.isPinned ? 0 : 45))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(droplet.isPinned ? SkyletTheme.skyBlue.opacity(0.25) : Color.white.opacity(0.08))
                            .background(.ultraThinMaterial)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(droplet.isPinned ? SkyletTheme.skyBlue.opacity(0.50) : Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(droplet.isPinned ? "Unpin (Close on click outside)" : "Pin (Stay awake)")
        }
    }

    @ViewBuilder
    private var resultLowerContent: some View {
        if isCompact {
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

                if droplet.isGraphEnabled {
                    convertedAmountCard
                        .frame(width: 160)
                        .frame(maxHeight: .infinity)
                } else {
                    convertedAmountCard
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    // MARK: - Large Converted Amount Card (Neutral Apple Liquid Glass — Item 6)

    private var convertedAmountCard: some View {
        let targetFormatted = CurrencyFormatter.format(
            amount: conversionResult?.targetAmount ?? 0,
            currency: conversionResult?.targetCurrency ?? targetCurrency
        )

        return Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(targetFormatted, forType: .string)
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
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
                // Neutral Frosted Liquid Glass Surface
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .background(.ultraThinMaterial)

                // Hairline Glass Rim
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)

                VStack(spacing: 3) {
                    if copiedConfirmation {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SkyletTheme.activeStatus)
                            Text("Copied to Clipboard")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white)
                        }
                    } else {
                        Text(targetFormatted)
                            .font(.system(size: isCompact ? 18 : 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 6)

                        HStack(spacing: 4) {
                            Text(conversionResult?.targetCurrency.rawValue ?? targetCurrency.rawValue)
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.55))
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 8.5))
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help("Click to copy converted amount")
    }

    // MARK: - Quick Currency Chip (Apple Liquid Glass — Item 2)

    private func quickCurrencyChip(code: CurrencyCode, isFirstRowLead: Bool, isFirstRowSecond: Bool) -> some View {
        let isDefault = (code == droplet.defaultInputCurrency)
        let isLocal = (code == droplet.localTargetCurrency)
        let isAccent = isDefault || isLocal

        let fillColor: Color = isDefault
            ? Color(red: 0.12, green: 0.48, blue: 0.95).opacity(0.85)
            : (isLocal ? Color(red: 0.35, green: 0.75, blue: 0.98).opacity(0.70) : Color.white.opacity(0.08))
        let strokeColor: Color = isDefault
            ? Color.white.opacity(0.50)
            : (isLocal ? Color.white.opacity(0.35) : Color.white.opacity(0.08))
        let strokeWidth: CGFloat = isAccent ? 1.0 : 0.5
        let fontWeight: Font.Weight = isAccent ? .bold : .medium

        let chipView = Button {
            selectShortcut(code: code)
        } label: {
            Text(code.rawValue)
                .font(.system(size: 9.5, weight: fontWeight))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(fillColor)
                        .background(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(strokeColor, lineWidth: strokeWidth)
                )
                .shadow(color: isDefault ? Color.blue.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .onDrag {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            return NSItemProvider(object: code.rawValue as NSString)
        }
        .help(isDefault ? "Default Input Currency (\(code.rawValue)) — Drag any currency here to replace" : (isLocal ? "Local Target Currency (\(code.rawValue)) — Drag any currency here to replace" : "Select \(code.rawValue)"))

        return Group {
            if isFirstRowLead {
                chipView.onDrop(of: ["public.text", "public.utf8-plain-text"], isTargeted: $isTargetedDefault) { providers in
                    handleDrop(providers: providers, targetSlot: .defaultInput)
                }
            } else if isFirstRowSecond {
                chipView.onDrop(of: ["public.text", "public.utf8-plain-text"], isTargeted: $isTargetedLocal) { providers in
                    handleDrop(providers: providers, targetSlot: .localTarget)
                }
            } else {
                chipView
            }
        }
    }

    // MARK: - Drag & Drop Handling

    private enum DropSlot {
        case defaultInput
        case localTarget
    }

    private func handleDrop(providers: [NSItemProvider], targetSlot: DropSlot) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, _ in
            var text: String?
            if let data = item as? Data {
                text = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                text = str
            } else if let nsStr = item as? NSString {
                text = nsStr as String
            }
            guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let droppedCode = CurrencyCode(raw) else { return }

            DispatchQueue.main.async {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                switch targetSlot {
                case .defaultInput:
                    self.droplet.defaultInputCurrency = droppedCode
                    self.sourceCurrency = droppedCode
                case .localTarget:
                    self.droplet.localTargetCurrency = droppedCode
                    self.targetCurrency = droppedCode
                }
                self.submitInput()
            }
        }
        return true
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

    private func selectShortcut(code: CurrencyCode) {
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sourceCurrency = code
            inputText = "100 \(code.rawValue)"
        } else {
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
    }

    private func recalculateWithCurrentInput() {
        let cleaned = editableAmountText.filter { "0123456789.".contains($0) }
        guard let amt = Decimal(string: cleaned), amt > 0 else { return }
        executeConversion(amount: amt, source: sourceCurrency, target: targetCurrency)
    }

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
        editableAmountText = "\(amount)"
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
                    self.sourceCurrency = result.sourceCurrency
                    self.targetCurrency = result.targetCurrency
                    self.editableAmountText = "\(result.sourceAmount)"
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
}
