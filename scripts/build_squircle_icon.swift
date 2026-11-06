import Cocoa
import CoreGraphics

func generateSquircleIcon() {
    let size: CGFloat = 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let ctx = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: Int(size) * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        print("Failed to create CGContext")
        return
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // 1. Transparent canvas initially
    ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

    // 2. Apple macOS Icon Squircle Path
    // Standard macOS squircle is inset slightly (about 32pt at 1024) with ~215pt continuous corner radius
    let iconRect = CGRect(x: 32, y: 32, width: size - 64, height: size - 64)
    let cornerRadius: CGFloat = 214.0
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Save state for clipped background
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // 3. Deep Midnight Glass Gradient Fill
    let gradColors = [
        NSColor(red: 0.07, green: 0.11, blue: 0.19, alpha: 1.00).cgColor,
        NSColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 1.00).cgColor
    ] as CFArray
    let gradLocations: [CGFloat] = [0.0, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: gradLocations) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: size / 2, y: size - 32),
            end: CGPoint(x: size / 2, y: 32),
            options: []
        )
    }

    // Subtle Radial Glow behind coin
    let glowColors = [
        NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.20).cgColor,
        NSColor(red: 0.10, green: 0.20, blue: 0.40, alpha: 0.00).cgColor
    ] as CFArray
    if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            glowGrad,
            startCenter: CGPoint(x: size / 2, y: size / 2),
            startRadius: 50,
            endCenter: CGPoint(x: size / 2, y: size / 2),
            endRadius: size * 0.45,
            options: .drawsAfterEndLocation
        )
    }

    // 4. Draw 3D Coin
    let coinPath = "Golden Coin with Rupee Underside_nobg.png"
    if let coinImage = NSImage(contentsOfFile: coinPath),
       let cgCoin = coinImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        let coinSize = size * 0.72
        let coinRect = CGRect(
            x: (size - coinSize) / 2,
            y: (size - coinSize) / 2,
            width: coinSize,
            height: coinSize
        )

        // Drop shadow for coin
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: NSColor.black.withAlphaComponent(0.60).cgColor)
        ctx.draw(cgCoin, in: coinRect)
        ctx.restoreGState()
    }

    // Specular Top Rim inside squircle
    let rimColors = [
        NSColor.white.withAlphaComponent(0.28).cgColor,
        NSColor.white.withAlphaComponent(0.04).cgColor
    ] as CFArray
    if let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.setLineWidth(3.0)
        ctx.addPath(squirclePath)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(
            rimGrad,
            start: CGPoint(x: size / 2, y: size - 32),
            end: CGPoint(x: size / 2, y: 32),
            options: []
        )
        ctx.restoreGState()
    }

    ctx.restoreGState() // restore squircle clip

    // 5. Save to mark.png
    guard let finalImage = ctx.makeImage() else {
        print("Failed to make CGImage")
        return
    }

    let rep = NSBitmapImageRep(cgImage: finalImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert to PNG")
        return
    }

    let markURL = URL(fileURLWithPath: "Skylet.icon/Assets/mark.png")
    try? pngData.write(to: markURL)
    print("Successfully generated squircle mark at \(markURL.path)")

    // Also update shots/icon_master_1024.png and sizes
    let iconMasterURL = URL(fileURLWithPath: "shots/icon_master_1024.png")
    try? pngData.write(to: iconMasterURL)

    let sizes: [Int] = [512, 256, 128, 64, 32, 16]
    for s in sizes {
        if let sCtx = CGContext(
            data: nil,
            width: s,
            height: s,
            bitsPerComponent: 8,
            bytesPerRow: s * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) {
            sCtx.interpolationQuality = .high
            sCtx.draw(finalImage, in: CGRect(x: 0, y: 0, width: s, height: s))
            if let sImg = sCtx.makeImage() {
                let sRep = NSBitmapImageRep(cgImage: sImg)
                if let sData = sRep.representation(using: .png, properties: [:]) {
                    try? sData.write(to: URL(fileURLWithPath: "shots/icon_\(s).png"))
                }
            }
        }
    }
    print("Successfully generated all icon sizes in shots/")
}

generateSquircleIcon()

