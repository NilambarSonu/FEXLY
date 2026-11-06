import Cocoa
import CoreGraphics

func generateFexlyIcons() {
    guard let sourceImage = NSImage(contentsOfFile: "Assets/Fexly.png") ?? NSImage(contentsOfFile: "Fexly.png") else {
        print("Error: Assets/Fexly.png not found")
        exit(1)
    }

    func renderIcon(size: Int) -> Data? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high

        // Authentic macOS Continuous Squircle
        let squircleRadius = CGFloat(size) * (214.0 / 1024.0)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let path = CGPath(roundedRect: rect, cornerWidth: squircleRadius, cornerHeight: squircleRadius, transform: nil)
        ctx.addPath(path)
        ctx.clip()

        if let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let srcW = CGFloat(cgImage.width)
            let srcH = CGFloat(cgImage.height)
            let scale = max(CGFloat(size) / srcW, CGFloat(size) / srcH)
            let destW = srcW * scale
            let destH = srcH * scale
            let destX = (CGFloat(size) - destW) / 2.0
            let destY = (CGFloat(size) - destH) / 2.0
            ctx.draw(cgImage, in: CGRect(x: destX, y: destY, width: destW, height: destH))
        }

        guard let outputCGImage = ctx.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: outputCGImage)
        return rep.representation(using: .png, properties: [:])
    }

    let sizes = [1024, 512, 256, 128, 64, 32, 16]
    for s in sizes {
        guard let data = renderIcon(size: s) else { continue }
        if s == 1024 {
            try? data.write(to: URL(fileURLWithPath: "shots/icon_master_1024.png"))
            try? data.write(to: URL(fileURLWithPath: "Assets/Fexly.png"))
        } else if s == 512 {
            // 512x512 is retina-sharp for Droppy launcher and shelf, and keeps bundle under 1.2MB!
            try? data.write(to: URL(fileURLWithPath: "Fexly.icon/Assets/mark.png"))
            try? data.write(to: URL(fileURLWithPath: "shots/icon_\(s).png"))
        } else {
            try? data.write(to: URL(fileURLWithPath: "shots/icon_\(s).png"))
        }
        print("Generated icon for size \(s)x\(s) (\(data.count) bytes)")
    }
}

generateFexlyIcons()
print("All Fexly icons successfully rendered.")
