//
//  SkyletRootView.swift
//  Skylet
//
//  Figma-faithful root container encasing Currency and Settings views
//  within the Droppy host container geometry.
//

import SwiftUI
import DroppyKit

public enum SkyletMode: String, CaseIterable, Identifiable {
    case currency = "Currency"
    case settings = "Settings"

    public var id: String { rawValue }
}

public struct SkyletRootView: View {
    @ObservedObject var droplet: SkyletDroplet
    let context: ShelfWidgetContext

    public init(droplet: SkyletDroplet, context: ShelfWidgetContext) {
        self.droplet = droplet
        self.context = context
    }

    public var body: some View {
        ZStack {
            // Main Panel Background (#414141 from Figma spec)
            SkyletTheme.mainPanel

            // Active View
            Group {
                switch droplet.selectedMode {
                case .currency:
                    CurrencyView(droplet: droplet, isCompact: context.isCompact)
                case .settings:
                    SettingsView(droplet: droplet)
                }
            }
            .padding(context.contentInsets)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(SkyletTheme.shelfShape(usesIslandCurvature: context.usesIslandCurvature))
        .animation(SkyletTheme.quickAnimation, value: droplet.selectedMode)
    }
}
