//
//  SettingsView.swift
//  Skylet
//
//  Figma-faithful Settings composition matching the user's design specification.
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
    @State private var showDefaultPicker: Bool = false
    @State private var showLocalPicker: Bool = false
    @State private var statusFeedback: String? = nil

    public init(droplet: SkyletDroplet) {
        self.droplet = droplet
    }

    public var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                // Header Row
                headerRow

                // Settings Form Card
                VStack(alignment: .leading, spacing: 8) {
                    // 1. API Key Row
                    apiKeyRow

                    // 2. Default Input Currency Row
                    defaultInputCurrencyRow

                    // 3. Choose Your Local Currency Row
                    chooseLocalCurrencyRow

                    // 4. Graph Toggle Row
                    graphToggleRow
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Done / Back Button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(SkyletTheme.quickAnimation) {
                            droplet.selectedMode = .currency
                        }
                    } label: {
                        Text("Done")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(SkyletTheme.inputAccent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            // Currency Pickers Overlay
            if showDefaultPicker {
                CurrencySelectorView(
                    selectedCurrency: $droplet.defaultInputCurrency,
                    onSelect: { code in
                        droplet.defaultInputCurrency = code
                        showDefaultPicker = false
                    },
                    onDismiss: { showDefaultPicker = false }
                )
                .zIndex(20)
            }

            if showLocalPicker {
                CurrencySelectorView(
                    selectedCurrency: $droplet.localTargetCurrency,
                    onSelect: { code in
                        droplet.localTargetCurrency = code
                        showLocalPicker = false
                    },
                    onDismiss: { showLocalPicker = false }
                )
                .zIndex(20)
            }
        }
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
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(SkyletTheme.secondaryText)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)

            Spacer()

            // Status Indicator (Figma top-right)
            HStack(spacing: 4) {
                Circle()
                    .fill(isVerifiedActive ? SkyletTheme.activeStatus : Color.white.opacity(0.40))
                    .frame(width: 5, height: 5)
                Text(isVerifiedActive ? "• API Active" : (hasStoredKey ? "• Stored" : "• Daily Reference"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isVerifiedActive ? SkyletTheme.activeStatus : SkyletTheme.secondaryText)
            }
        }
    }

    // MARK: - API Key Row

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
                        if isRevealed {
                            SkyletIcon.EyeSlashShape()
                                .stroke(Color.white.opacity(0.80), lineWidth: 1.5)
                                .frame(width: 13, height: 13)
                        } else {
                            SkyletIcon.EyeShape()
                                .stroke(Color.white.opacity(0.80), lineWidth: 1.5)
                                .frame(width: 13, height: 13)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(isRevealed ? "Hide key" : "Show key")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
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

                // Info Button
                Button {
                    showInfoPopover.toggle()
                } label: {
                    SkyletIcon.InfoBubbleShape()
                        .stroke(Color.white.opacity(0.60), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfoPopover) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Twelve Data Forex API Key")
                            .font(.system(size: 11, weight: .bold))
                        Text("Enables genuine real-time USD/INR quotes and intraday charts. Stored securely in macOS Keychain.\n\nGet a free key at twelvedata.com/forex.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(10)
                    .frame(width: 200)
                }
            }

            if let msg = statusFeedback {
                Text(msg)
                    .font(.system(size: 9.5))
                    .foregroundStyle(SkyletTheme.skyBlue)
                    .padding(.leading, 58)
            }
        }
    }

    // MARK: - Default Input Currency Row

    private var defaultInputCurrencyRow: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Default")
                    .font(.system(size: 9.5, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.40))
                Text("Input Currency :")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()

            Button {
                showDefaultPicker = true
            } label: {
                let symbol = CurrencyMetadata.symbol(for: droplet.defaultInputCurrency)
                Text("\(symbol) \(droplet.defaultInputCurrency.rawValue)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - Choose Local Currency Row

    private var chooseLocalCurrencyRow: some View {
        HStack(spacing: 8) {
            Text("Choose Your Local Currency :")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Button {
                showLocalPicker = true
            } label: {
                let symbol = CurrencyMetadata.symbol(for: droplet.localTargetCurrency)
                Text("\(symbol) \(droplet.localTargetCurrency.rawValue)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - Graph Toggle Row

    private var graphToggleRow: some View {
        HStack(spacing: 8) {
            Text("Graph :")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Toggle("", isOn: $droplet.isGraphEnabled)
                .toggleStyle(SwitchToggleStyle(tint: SkyletTheme.skyBlue))
                .labelsHidden()
                .scaleEffect(0.75)
        }
    }

    // MARK: - Keychain Helper

    private func loadStoredKey() {
        if let key = droplet.keychain.get(key: "twelvedata_api_key"), !key.isEmpty {
            self.apiKeyInput = key
            self.hasStoredKey = true
            // Test connection to verify API Active status
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
