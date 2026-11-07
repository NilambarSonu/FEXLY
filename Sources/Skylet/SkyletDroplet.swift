//
//  SkyletDroplet.swift
//  Fexly
//

import Combine
import SwiftUI
import DroppyKit
import SkyletCore

/// Fexly: Native DroppyKit utility providing real-time foreign exchange intelligence,
/// live Twelve Data forex rates, honest provenance tracking, and instant INR conversion for macOS.
@MainActor
public final class FexlyDroplet: NSObject, ObservableObject, Droplet {
    /// Must equal `DroppyDropletID` in Info.plist and `id` in `droplet.json`.
    public nonisolated static let id: DropletID = "fexly"
    public nonisolated static let widgetID: ShelfWidgetID = "fexly"

    /// Instance-side identifier conforming to Droplet protocol.
    public nonisolated var id: DropletID { Self.id }

    private var host: DropletHost?
    private var cancellables = Set<AnyCancellable>()
    private let activitySubject = CurrentValueSubject<LiveActivityState?, Never>(nil)
    private var liveActivityTimerTask: Task<Void, Never>?

    public let rateService: CurrencyRateService
    public let historyService: CurrencyHistoryService
    public let keychain: KeychainStoring

    @Published public var selectedMode: FexlyMode = .currency {
        didSet {
            notifyLayoutChanged()
        }
    }
    @Published public var isAPIActive: Bool = false
    @Published public private(set) var latestConversion: CurrencyConversionResult?
    @Published public var isPinned: Bool = false {
        didSet {
            host?.shelf.setHoldsOpen(isPinned)
        }
    }

    public func notifyLayoutChanged() {
        host?.shelf.invalidateLayout(for: Self.widgetID)
    }

    // Persisted User Preferences (Support both Fexly and legacy Skylet keys)
    @Published public var defaultInputCurrency: CurrencyCode {
        didSet {
            UserDefaults.standard.set(defaultInputCurrency.rawValue, forKey: "fexly_default_input_currency")
            UserDefaults.standard.set(defaultInputCurrency.rawValue, forKey: "skylet_default_input_currency")
        }
    }
    @Published public var localTargetCurrency: CurrencyCode {
        didSet {
            UserDefaults.standard.set(localTargetCurrency.rawValue, forKey: "fexly_local_target_currency")
            UserDefaults.standard.set(localTargetCurrency.rawValue, forKey: "skylet_local_target_currency")
        }
    }
    @Published public var isGraphEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGraphEnabled, forKey: "fexly_graph_enabled")
            UserDefaults.standard.set(isGraphEnabled, forKey: "skylet_graph_enabled")
        }
    }
    @Published public var selectedGraphRange: CurrencyHistoryRange {
        didSet {
            UserDefaults.standard.set(selectedGraphRange.rawValue, forKey: "fexly_selected_graph_range")
            UserDefaults.standard.set(selectedGraphRange.rawValue, forKey: "skylet_selected_graph_range")
        }
    }

    public init(
        keychain: KeychainStoring = MacOSKeychainManager.shared,
        rateService: CurrencyRateService? = nil,
        historyService: CurrencyHistoryService? = nil
    ) {
        self.keychain = keychain
        self.rateService = rateService ?? CurrencyRateService(
            realTimeProvider: TwelveDataRateProvider(keychain: keychain),
            primaryReferenceProvider: ExchangeRateAPIProvider(),
            secondaryReferenceProvider: FrankfurterRateProvider(),
            cache: CurrencyRateCache.shared
        )

        let resolvedHistory = historyService ?? CurrencyHistoryService(
            cache: CurrencyHistoryCache(),
            twelveDataProvider: TwelveDataHistoryProvider(apiKeyProvider: { [keychain] in
                keychain.get(key: "twelvedata_api_key")
            }),
            fallbackProvider: FrankfurterHistoryProvider()
        )
        self.historyService = resolvedHistory

        let savedInput = UserDefaults.standard.string(forKey: "fexly_default_input_currency")
            ?? UserDefaults.standard.string(forKey: "skylet_default_input_currency") ?? "USD"
        self.defaultInputCurrency = CurrencyCode(savedInput) ?? .usd

        let savedTarget = UserDefaults.standard.string(forKey: "fexly_local_target_currency")
            ?? UserDefaults.standard.string(forKey: "skylet_local_target_currency") ?? "INR"
        self.localTargetCurrency = CurrencyCode(savedTarget) ?? .inr

        if UserDefaults.standard.object(forKey: "fexly_graph_enabled") != nil {
            self.isGraphEnabled = UserDefaults.standard.bool(forKey: "fexly_graph_enabled")
        } else if UserDefaults.standard.object(forKey: "skylet_graph_enabled") != nil {
            self.isGraphEnabled = UserDefaults.standard.bool(forKey: "skylet_graph_enabled")
        } else {
            self.isGraphEnabled = true
        }

        let savedRange = UserDefaults.standard.string(forKey: "fexly_selected_graph_range")
            ?? UserDefaults.standard.string(forKey: "skylet_selected_graph_range") ?? "1M"
        self.selectedGraphRange = CurrencyHistoryRange(rawValue: savedRange) ?? .oneMonth

        super.init()
        verifyAPIKeyInBackground()
    }

    public func verifyAPIKeyInBackground() {
        guard let key = keychain.get(key: "twelvedata_api_key"), !key.isEmpty else {
            self.isAPIActive = false
            return
        }
        Task { [weak self] in
            guard let self = self else { return }
            let provider = TwelveDataRateProvider(keychain: self.keychain)
            do {
                _ = try await provider.fetchRate(from: .usd, to: .inr)
                await MainActor.run {
                    self.isAPIActive = true
                }
            } catch {
                await MainActor.run {
                    self.isAPIActive = false
                }
            }
        }
    }

    // MARK: - Lifecycle

    public func activate(host: DropletHost) throws {
        self.host = host
        host.log.info("Fexly activated — Real-Time FX & Currency Intelligence")
        verifyAPIKeyInBackground()
        publishAppropriateLiveActivity()
    }

    public func deactivate() {
        if isPinned {
            isPinned = false
            host?.shelf.setHoldsOpen(false)
        }
        liveActivityTimerTask?.cancel()
        liveActivityTimerTask = nil
        cancellables.removeAll()
        latestConversion = nil
        activitySubject.send(nil)
        host = nil
    }

    public func updateLatestConversion(_ result: CurrencyConversionResult) {
        self.latestConversion = result
        publishAppropriateLiveActivity()

        // As requested by user: Live Activity stays visible for 5 seconds after conversion, then disappears
        liveActivityTimerTask?.cancel()
        liveActivityTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            self?.dismissLiveActivity()
        }
    }

    public func dismissLiveActivity() {
        activitySubject.send(nil)
    }

    private func publishAppropriateLiveActivity() {
        if let conv = latestConversion {
            let formattedTarget = CurrencyFormatter.format(amount: conv.targetAmount, currency: conv.targetCurrency)
            activitySubject.send(
                LiveActivityState(
                    priority: 150,
                    accessibilityTitle: "Skylet conversion: \(conv.sourceAmount) \(conv.sourceCurrency.rawValue) = \(formattedTarget)",
                    isInteractive: true
                )
            )
        } else {
            activitySubject.send(nil)
        }
    }
}

// MARK: - ShelfWidgetProviding

extension FexlyDroplet: ShelfWidgetProviding {
    public var widgetDescriptors: [ShelfWidgetDescriptor] {
        let cardHeight: CGFloat = (selectedMode == .settings) ? 236 : 160
        return [
            ShelfWidgetDescriptor(
                id: Self.widgetID,
                title: "Fexly",
                systemImage: "sparkles",
                layoutTraits: ShelfWidgetLayoutTraits(
                    preferredSoloWidth: 420,
                    preferredPairedWidth: 210,
                    contentHeight: .fixed(cardHeight)
                ),
                searchKeywords: [
                    "currency", "converter", "inr", "rupee",
                    "forex", "exchange", "rates", "twelve data", "fexly"
                ]
            )
        ]
    }

    public func makeWidgetView(_ id: ShelfWidgetID, context: ShelfWidgetContext) -> AnyView {
        AnyView(SkyletRootView(droplet: self, context: context))
    }
}

// MARK: - LiveActivityProviding

extension FexlyDroplet: LiveActivityProviding {
    public var liveActivityState: AnyPublisher<LiveActivityState?, Never> {
        activitySubject.eraseToAnyPublisher()
    }

    public func makeCompactLeading() -> AnyView {
        AnyView(
            Group {
                if let conv = latestConversion {
                    Text(CurrencyFormatter.format(amount: conv.sourceAmount, currency: conv.sourceCurrency))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                        .padding(.trailing, DroppySpacing.xs)
                } else {
                    EmptyView()
                }
            }
        )
    }

    public func makeCompactTrailing() -> AnyView {
        AnyView(
            Group {
                if let conv = latestConversion {
                    Text(CurrencyFormatter.format(amount: conv.targetAmount, currency: conv.targetCurrency))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                        .padding(.leading, DroppySpacing.xs)
                } else {
                    EmptyView()
                }
            }
        )
    }

    public func makeExpanded(context: LiveActivityContext) -> AnyView {
        AnyView(EmptyView())
    }
}

// MARK: - SettingsPaneProviding

extension FexlyDroplet: SettingsPaneProviding {
    public func makeSettingsPane(context: SettingsPaneContext) -> AnyView {
        AnyView(SettingsView(droplet: self))
    }

    public var settingsSearchEntries: [SettingsSearchEntry] {
        [
            SettingsSearchEntry(title: "Twelve Data API Key", keywords: ["currency", "twelve data", "forex", "key", "inr", "fexly"])
        ]
    }
}

public typealias SkyletDroplet = FexlyDroplet
