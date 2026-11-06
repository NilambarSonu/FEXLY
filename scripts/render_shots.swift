import SwiftUI
import AppKit

// MARK: - Droppy Tokens Stub for Renderer
public enum DroppySpacing {
    public static let xs: CGFloat = 4
    public static let xsm: CGFloat = 6
    public static let sm: CGFloat = 8
    public static let smd: CGFloat = 10
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
}

public enum DroppyRadius {
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 10
    public static let lg: CGFloat = 14
    public static let full: CGFloat = 999
}

// MARK: - Color & Style Constants matching SkyletTheme
public enum Theme {
    public static let skyBlue = Color(red: 0.22, green: 0.74, blue: 0.97)
    public static let primaryBlue = Color(red: 0.08, green: 0.61, blue: 0.91)
    public static let lightSky = Color(red: 0.49, green: 0.83, blue: 0.99)
    
    public static let background = Color(red: 0.07, green: 0.08, blue: 0.11)
    public static let cardBackground = Color(red: 0.11, green: 0.13, blue: 0.18)
    public static let cardBorder = Color.white.opacity(0.08)
    
    public static let primaryText = Color.white
    public static let secondaryText = Color(white: 0.65)
    public static let tertiaryText = Color(white: 0.42)
    
    public static let statusLive = Color(red: 0.20, green: 0.83, blue: 0.55)
    public static let statusDelayed = Color(red: 1.0, green: 0.76, blue: 0.24)
    
    public static let shelfCornerRadius: CGFloat = 18.0
    public static let shelfShape = RoundedRectangle(cornerRadius: 18.0, style: .continuous)
}

// MARK: - Notch Container Shell
public struct DroppyNotchShell<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: DroppySpacing.sm) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.skyBlue)
                    Text("Skylet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.statusLive)
                        .frame(width: 5, height: 5)
                    Text("LIVE FX")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.statusLive)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Theme.statusLive.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, DroppySpacing.md)
            .padding(.top, DroppySpacing.smd)
            .padding(.bottom, DroppySpacing.sm)

            Divider()
                .background(Color.white.opacity(0.06))

            // Body
            content
                .padding(DroppySpacing.md)
        }
        .frame(width: 340)
        .background(Theme.background)
        .clipShape(Theme.shelfShape)
        .overlay(
            Theme.shelfShape
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Screenshots Generation Views
public struct CurrencyMainView: View {
    public var body: some View {
        DroppyNotchShell {
            VStack(alignment: .leading, spacing: DroppySpacing.md) {
                // Input Row
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.skyBlue)
                        .font(.system(size: 13, weight: .semibold))
                    Text("$889.86")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tertiaryText)
                    Text("Paste")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Quick Currency Selector Chips
                HStack(spacing: 6) {
                    Text("Convert:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.tertiaryText)
                    chip(text: "USD", isSelected: true)
                    chip(text: "EUR", isSelected: false)
                    chip(text: "GBP", isSelected: false)
                    chip(text: "JPY", isSelected: false)
                    chip(text: "AED", isSelected: false)
                }

                // Result Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("₹84,754.67")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.statusLive)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.statusLive)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.statusLive.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Text("1 USD = ₹95.2450")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.secondaryText)
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.tertiaryText)
                        Text("Twelve Data")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.tertiaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                            Text("Copy")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.skyBlue)
                    }
                }
                .padding(12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DroppyRadius.lg, style: .continuous)
                        .stroke(Theme.skyBlue.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private func chip(text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isSelected ? Theme.skyBlue : Color.white.opacity(0.06))
            .clipShape(Capsule())
    }
}

// MARK: - Rendering Helper
@MainActor
func renderToPNG<V: View>(view: V, size: CGSize, path: String) {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = CGRect(origin: .zero, size: size)
    hostingView.layoutSubtreeIfNeeded()

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        print("Failed to allocate bitmap rep for \(path)")
        return
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert to PNG for \(path)")
        return
    }
    let url = URL(fileURLWithPath: path)
    try? pngData.write(to: url)
    print("Saved \(path) (\(Int(size.width))x\(Int(size.height)))")
}

@MainActor
func generateAllScreenshots() {
    print("==> Rendering SKYLET Currency Intelligence Screenshots...")

    let shelfSize = CGSize(width: 340, height: 260)
    renderToPNG(view: CurrencyMainView(), size: shelfSize, path: "shots/currency_main.png")
    renderToPNG(view: CurrencyMainView(), size: shelfSize, path: "Assets/currency_main.png")

    print("==> Screenshots generated successfully!")
}

Task { @MainActor in
    generateAllScreenshots()
    exit(0)
}

dispatchMain()
