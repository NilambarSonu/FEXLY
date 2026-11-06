//
//  SettingsView.swift
//  Skylet
//
//  Apple Liquid Glass Settings interface matching native macOS guidelines.
//

import SwiftUI
import AppKit
import DroppyKit
import SkyletCore

public struct SettingsView: View {
    @ObservedObject var droplet: SkyletDroplet

    @State private var apiKeyInput: String = ""
    @State private var isRevealed: Bool = false
    @State private var hasStoredKey: Bool = false
    @State private var isVerifiedActive: Bool = false
    @State private var showInfoPopover: Bool = false
    @State private var statusFeedback: String? = nil

    public init(droplet: SkyletDroplet) {
        self.droplet = droplet
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Row
            headerRow

            // Settings Form Card (Liquid Glass Tile)
            VStack(alignment: .leading, spacing: 8) {
                // 1. API Key Row
                apiKeyRow

                // Section label "Default" above the line (Item 6)
                Text("Default")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(.top, 2)

                Divider()
                    .background(Color.white.opacity(0.10))

                // 2. Input Currency Row (Item 5 & 6: Single dropdown chevron, no duplicate label)
                inputCurrencyRow

                // 3. Choose Your Local Currency Row (Item 5 & 6)
                chooseLocalCurrencyRow

                Divider()
                    .background(Color.white.opacity(0.10))

                // 4. Graph Toggle Row (Item 4: Fully visible with smooth expanded height)
                graphToggleRow
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .onAppear {
            loadStoredKey()
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    droplet.selectedMode = .currency
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10.5, weight: .bold))
                    Text("Back")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial)
                )
                .clipShape(Capsule(style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back to Currency Converter")

            Spacer()

            Text("Settings")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)

            Spacer()

            // Status Indicator (Item 7: Single crisp dot close to text)
            let statusColor = isVerifiedActive ? SkyletTheme.activeStatus : (hasStoredKey ? SkyletTheme.statusDelayed : SkyletTheme.secondaryText)
            let statusTitle = isVerifiedActive ? "API Active" : (hasStoredKey ? "Stored" : "Daily Reference")
            HStack(spacing: 3) {
                Text("•")
                    .font(.system(size: 11, weight: .bold))
                Text(statusTitle)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(statusColor)
        }
    }

    // MARK: - API Key Row with 3-Step Guide Popover (Item 12)

    private var apiKeyRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: 6) {
                Text("Api key")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 52, alignment: .leading)

                // Apple Liquid Glass API Key Field
                HStack(spacing: 4) {
                    Group {
                        if isRevealed {
                            TextField("", text: $apiKeyInput)
                        } else {
                            SecureField("", text: $apiKeyInput)
                        }
                    }
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                    .onSubmit { saveAPIKey() }

                    // Eye Icon (reveal / hide)
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(isRevealed ? "Hide key" : "Show key")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .background(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )

                // Info Button with 3-Step Bullet Guide Popover
                Button {
                    showInfoPopover.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Click for 3-step guide to get a free Twelve Data API key")
                .popover(isPresented: $showInfoPopover, arrowEdge: .trailing) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(SkyletTheme.skyBlue)
                            Text("How to Get a Free API Key")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(Color.white)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("1.")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SkyletTheme.skyBlue)
                                Text("Go to **twelvedata.com/forex** and create a free account (no credit card needed).")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            HStack(alignment: .top, spacing: 6) {
                                Text("2.")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SkyletTheme.skyBlue)
                                Text("Copy your personal API Key from the Twelve Data Dashboard.")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            HStack(alignment: .top, spacing: 6) {
                                Text("3.")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SkyletTheme.skyBlue)
                                Text("Paste it into the API key field and press Return to verify.")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.15))

                        Text("• Unlocks genuine live Forex rates & intraday 1D/5D charts.\n• 8 requests/min free tier is plenty for Skylet.")
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    .padding(12)
                    .frame(width: 250)
                }
            }

            if let msg = statusFeedback {
                Text(msg)
                    .font(.system(size: 9))
                    .foregroundStyle(SkyletTheme.skyBlue)
                    .padding(.leading, 58)
            }
        }
    }

    // MARK: - Input Currency Row (Native Apple Menu — Item 5 & 6)

    private var inputCurrencyRow: some View {
        HStack(spacing: 8) {
            Text("Input Currency :")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Menu {
                ForEach(CurrencyCode.allCases, id: \.self) { code in
                    Button {
                        droplet.defaultInputCurrency = code
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    } label: {
                        HStack {
                            Text("\(CurrencyMetadata.symbol(for: code))  \(code.rawValue) — \(CurrencyMetadata.name(for: code))")
                            if droplet.defaultInputCurrency == code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                let symbol = CurrencyMetadata.symbol(for: droplet.defaultInputCurrency)
                HStack(spacing: 4) {
                    Text("\(symbol) \(droplet.defaultInputCurrency.rawValue)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .background(.ultraThinMaterial)
                )
                .clipShape(Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }

    // MARK: - Choose Local Currency Row (Native Apple Menu — Item 5 & 6)

    private var chooseLocalCurrencyRow: some View {
        HStack(spacing: 8) {
            Text("Choose Your Local Currency :")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Menu {
                ForEach(CurrencyCode.allCases, id: \.self) { code in
                    Button {
                        droplet.localTargetCurrency = code
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    } label: {
                        HStack {
                            Text("\(CurrencyMetadata.symbol(for: code))  \(code.rawValue) — \(CurrencyMetadata.name(for: code))")
                            if droplet.localTargetCurrency == code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                let symbol = CurrencyMetadata.symbol(for: droplet.localTargetCurrency)
                HStack(spacing: 4) {
                    Text("\(symbol) \(droplet.localTargetCurrency.rawValue)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .background(.ultraThinMaterial)
                )
                .clipShape(Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }

    // MARK: - Graph Toggle Row (Item 8: Fits without bottom cutoff)

    private var graphToggleRow: some View {
        HStack(spacing: 8) {
            Text("Graph :")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Toggle("", isOn: $droplet.isGraphEnabled)
                .toggleStyle(SwitchToggleStyle(tint: SkyletTheme.skyBlue))
                .labelsHidden()
                .scaleEffect(0.72)
        }
    }

    // MARK: - Keychain Helper

    private func loadStoredKey() {
        if let key = droplet.keychain.get(key: "twelvedata_api_key"), !key.isEmpty {
            self.apiKeyInput = key
            self.hasStoredKey = true
            Task {
                await verifyKey(key)
            }
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try? droplet.keychain.delete(key: "twelvedata_api_key")
            hasStoredKey = false
            isVerifiedActive = false
            statusFeedback = "Key removed from Keychain."
        } else {
            do {
                try droplet.keychain.save(key: "twelvedata_api_key", value: trimmed)
                hasStoredKey = true
                statusFeedback = "Saved in macOS Keychain."
                Task {
                    await verifyKey(trimmed)
                }
            } catch {
                statusFeedback = "Keychain error: \(error.localizedDescription)"
            }
        }
    }

    private func verifyKey(_ key: String) async {
        let provider = TwelveDataRateProvider(keychain: droplet.keychain)
        do {
            _ = try await provider.fetchRate(from: .usd, to: .inr)
            await MainActor.run {
                self.isVerifiedActive = true
                self.statusFeedback = "API Active & Verified."
            }
        } catch {
            await MainActor.run {
                self.isVerifiedActive = false
                self.statusFeedback = "Key verification failed."
            }
        }
    }
}
