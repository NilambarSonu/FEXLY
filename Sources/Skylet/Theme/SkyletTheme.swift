//
//  SkyletTheme.swift
//  Skylet
//
//  Skylet Design System & Visual Foundation
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import DroppyKit

/// Unified Design System for Skylet conforming to DroppyKit's design language.
public enum SkyletTheme {
    // MARK: - Native Droppy & Apple Liquid Glass Design System

    /// Droppy shelf translucent base
    public static let shelfGlassBackground = Color.black.opacity(0.68)

    /// Subtle frosted glass surface fill for inner cards
    public static let glassCardBackground = Color.white.opacity(0.06)

    /// Hairline glass rim for cards and containers
    public static let glassCardBorder = Color.white.opacity(0.12)

    /// Elevated glass surface under hover
    public static let glassCardHover = Color.white.opacity(0.14)

    /// Liquid Glass pill fill for search and controls
    public static let glassPillBackground = Color.white.opacity(0.09)

    /// Liquid Glass pill border
    public static let glassPillBorder = Color.white.opacity(0.16)

    /// Elevated glass pill under hover
    public static let glassPillHover = Color.white.opacity(0.18)

    /// Apple Liquid Glass gradient for converted amount hero card
    public static let glassConvertedGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.72, blue: 0.60).opacity(0.38),
            Color(red: 0.05, green: 0.42, blue: 0.50).opacity(0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Luminous glass border for converted amount hero card
    public static let glassConvertedBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.35),
            Color(red: 0.20, green: 0.85, blue: 0.75).opacity(0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Legacy / Semantic Fallbacks (Transformed to Premium Glass)

    /// Outer background: Native translucent notch backdrop
    public static let outerBackground = Color.black.opacity(0.80)

    /// Main panel surface: Frosted notch glass instead of opaque grey
    public static let mainPanel = Color.black.opacity(0.65)

    /// Input accent pill: Liquid Glass pill fill
    public static let inputAccent = Color.white.opacity(0.10)

    /// Light controls: Frosted glass chip fill
    public static let lightControls = Color.white.opacity(0.08)

    /// Active provider status tint: Apple Mint (#34D399)
    public static let activeStatus = Color(red: 0.20, green: 0.83, blue: 0.60)

    /// Graph card background: Frosted glass tile
    public static let graphBackground = Color.white.opacity(0.05)

    /// Chart line color: Restrained coral/salmon (#F87171)
    public static let chartLine = Color(red: 0xF8/255.0, green: 0x71/255.0, blue: 0x71/255.0)

    /// Pure crisp white text for controls
    public static let darkInputText = Color.white


    // MARK: - Brand Palette (Sky-Blue Accent Ladder)

    /// Primary brand accent: #38BDF8
    public static let skyBlue = Color(red: 0.22, green: 0.74, blue: 0.97)

    /// Deep brand accent for pressed or contrasting states: #159BE8
    public static let primaryBlue = Color(red: 0.08, green: 0.61, blue: 0.91)

    /// Soft sky highlight for subtle backgrounds and badges: #7DD3FC
    public static let lightSky = Color(red: 0.49, green: 0.83, blue: 0.99)

    // MARK: - Dark Chrome Surface Hierarchy

    /// Midnight base surface: #0B1220
    public static let midnightSurface = Color(red: 0.043, green: 0.071, blue: 0.125)

    /// Secondary elevated surface: #111B2B
    public static let secondarySurface = Color(red: 0.067, green: 0.106, blue: 0.169)

    /// Prominently elevated surface: #172438
    public static let elevatedSurface = Color(red: 0.090, green: 0.141, blue: 0.220)

    // MARK: - Restrained Semantic Status Tints

    /// Restrained green for live quote
    public static let statusLive = Color(red: 0.20, green: 0.78, blue: 0.50)

    /// Restrained amber for delayed quotes
    public static let statusDelayed = Color(red: 0.96, green: 0.72, blue: 0.25)

    /// Restrained blue/slate for daily reference rates
    public static let statusReference = Color(red: 0.40, green: 0.65, blue: 0.90)

    /// Restrained muted grey for cached entries
    public static let statusCached = Color.white.opacity(0.55)

    /// Restrained red for errors or unavailable data
    public static let statusError = Color(red: 0.95, green: 0.38, blue: 0.38)

    // MARK: - Native DroppyKit Adaptive Inks

    /// Primary foreground on notch/shelf chrome (pure white)
    public static var primaryText: Color {
        AdaptiveColors.notchSurfacePrimaryText
    }

    /// Secondary foreground on notch/shelf chrome (white 0.82)
    public static var secondaryText: Color {
        AdaptiveColors.notchSurfaceSecondaryText
    }

    /// Tertiary muted foreground on notch/shelf chrome (white 0.60)
    public static var tertiaryText: Color {
        AdaptiveColors.notchSurfaceTertiaryText
    }

    /// Subtle card and chip fill (white 0.10)
    public static var cardFill: Color {
        AdaptiveColors.notchSurfaceCardFill
    }

    /// Interactive control background (white 0.07 at rest)
    public static var controlBackground: Color {
        Color.white.opacity(0.07)
    }

    /// Interactive control hover background (white 0.13)
    public static var controlHoverBackground: Color {
        Color.white.opacity(0.13)
    }

    /// Interactive control pressed background (white 0.18)
    public static var controlPressedBackground: Color {
        Color.white.opacity(0.18)
    }

    // MARK: - Typography Hierarchy

    /// Hero monetary value (large, bold, rounded with tabular numbers)
    public static let heroAmountFont = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Medium monetary value (for paired/compact or secondary display)
    public static let mediumAmountFont = Font.system(size: 18, weight: .semibold, design: .rounded)

    /// Value font for standard displays
    public static let valueFont = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Amount input text field font
    public static let inputFont = Font.system(size: 13, weight: .regular)

    /// Section header and prominent row titles
    public static let headerFont = Font.system(size: 12, weight: .semibold)

    /// Subhead for currency codes and secondary pairs
    public static let subheadFont = Font.system(size: 11, weight: .medium)

    /// Button and interactive pill labels
    public static let buttonFont = Font.system(size: 11, weight: .medium)

    /// Compact button and pill font
    public static let compactButtonFont = Font.system(size: 10, weight: .medium)

    /// Small status caption and metadata
    public static let captionFont = Font.system(size: 10, weight: .regular)

    /// Micro font for badges and tags
    public static let microFont = Font.system(size: 9, weight: .medium)

    // MARK: - Native DroppyKit Geometry & Continuous Radii

    /// Standard shelf widget corner radius (18pt continuous)
    public static let shelfCornerRadius: CGFloat = DroppyShellMetrics.shelfWidgetCornerRadius

    /// Full-bleed island shelf widget corner radius (26.5pt continuous)
    public static let shelfFullBleedCornerRadius: CGFloat = DroppyShellMetrics.shelfFullBleedCornerRadius

    /// Standard container shape for the widget
    public static func shelfShape(usesIslandCurvature: Bool = false) -> RoundedRectangle {
        RoundedRectangle(
            cornerRadius: usesIslandCurvature ? shelfFullBleedCornerRadius : shelfCornerRadius,
            style: .continuous
        )
    }

    // MARK: - Micro-Animation Timings

    /// Quick response feedback (tap, hover)
    public static let quickAnimation: Animation = .easeOut(duration: 0.12)

    /// Standard interactive transition (mode switch, swap, refresh)
    public static let standardAnimation: Animation = .spring(response: 0.28, dampingFraction: 0.82)

    /// Gentle layout transition
    public static let smoothAnimation: Animation = .easeInOut(duration: 0.22)
}
