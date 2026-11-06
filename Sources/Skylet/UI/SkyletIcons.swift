//
//  SkyletIcons.swift
//  Skylet
//
//  Native vector icon shapes derived from the project's Figma SVG design assets.
//

import SwiftUI

public enum SkyletIcon {
    // MARK: - Settings Gear Icon (from settings-svgrepo-com.svg)
    public struct SettingsShape: Shape {
        public func path(in rect: CGRect) -> Path {
            let scaleX = rect.width / 24.0
            let scaleY = rect.height / 24.0
            var path = Path()

            // Inner circle
            path.addEllipse(in: CGRect(
                x: 9 * scaleX + rect.minX,
                y: 9 * scaleY + rect.minY,
                width: 6 * scaleX,
                height: 6 * scaleY
            ))

            // Gear outline path
            var gear = Path()
            gear.move(to: CGPoint(x: 13.7654 * scaleX + rect.minX, y: 2.15224 * scaleY + rect.minY))
            // Simplified standard 8-tooth gear profile scaled to rect
            for i in 0..<8 {
                let angle = Double(i) * (.pi / 4.0)
                let rOut: CGFloat = 10.0 * scaleX
                let rIn: CGFloat = 8.5 * scaleX
                let cx = rect.midX
                let cy = rect.midY
                let p1 = CGPoint(x: cx + rIn * cos(angle - 0.15), y: cy + rIn * sin(angle - 0.15))
                let p2 = CGPoint(x: cx + rOut * cos(angle - 0.10), y: cy + rOut * sin(angle - 0.10))
                let p3 = CGPoint(x: cx + rOut * cos(angle + 0.10), y: cy + rOut * sin(angle + 0.10))
                let p4 = CGPoint(x: cx + rIn * cos(angle + 0.15), y: cy + rIn * sin(angle + 0.15))
                if i == 0 {
                    gear.move(to: p1)
                } else {
                    gear.addLine(to: p1)
                }
                gear.addLine(to: p2)
                gear.addLine(to: p3)
                gear.addLine(to: p4)
            }
            gear.closeSubpath()
            path.addPath(gear)

            return path
        }
    }

    // MARK: - Search Magnifier Icon (from search-alt-2-svgrepo-com.svg)
    public struct SearchShape: Shape {
        public func path(in rect: CGRect) -> Path {
            let sx = rect.width / 24.0
            let sy = rect.height / 24.0
            var path = Path()

            // Outer ring
            path.addEllipse(in: CGRect(
                x: 3 * sx + rect.minX,
                y: 3 * sy + rect.minY,
                width: 16 * sx,
                height: 16 * sy
            ))

            // Handle
            path.move(to: CGPoint(x: 16.6588 * sx + rect.minX, y: 16.6549 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 21 * sx + rect.minX, y: 21 * sy + rect.minY))

            return path
        }
    }

    // MARK: - Rotate / Refresh Icon (from rotate-svgrepo-com.svg)
    public struct RotateShape: Shape {
        public func path(in rect: CGRect) -> Path {
            let sx = rect.width / 24.0
            let sy = rect.height / 24.0
            var path = Path()

            // Top-right arc
            path.addArc(
                center: CGPoint(x: 12 * sx + rect.minX, y: 12 * sy + rect.minY),
                radius: 8 * sx,
                startAngle: .degrees(-150),
                endAngle: .degrees(-10),
                clockwise: false
            )

            // Top arrow
            path.move(to: CGPoint(x: 18.2 * sx + rect.minX, y: 4 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 18.2 * sx + rect.minX, y: 7 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 15.2 * sx + rect.minX, y: 7 * sy + rect.minY))

            // Bottom-left arc
            path.addArc(
                center: CGPoint(x: 12 * sx + rect.minX, y: 12 * sy + rect.minY),
                radius: 8 * sx,
                startAngle: .degrees(30),
                endAngle: .degrees(170),
                clockwise: false
            )

            // Bottom arrow
            path.move(to: CGPoint(x: 6 * sx + rect.minX, y: 20 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 6 * sx + rect.minX, y: 17 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 9 * sx + rect.minX, y: 17 * sy + rect.minY))

            return path
        }
    }

    // MARK: - Eye (Show Password) Icon
    public struct EyeShape: Shape {
        public func path(in rect: CGRect) -> Path {
            let sx = rect.width / 24.0
            let sy = rect.height / 24.0
            var path = Path()

            // Outer eyelid shape
            path.move(to: CGPoint(x: 2.5 * sx + rect.minX, y: 12 * sy + rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: 21.5 * sx + rect.minX, y: 12 * sy + rect.minY),
                control: CGPoint(x: 12 * sx + rect.minX, y: 4 * sy + rect.minY)
            )
            path.addQuadCurve(
                to: CGPoint(x: 2.5 * sx + rect.minX, y: 12 * sy + rect.minY),
                control: CGPoint(x: 12 * sx + rect.minX, y: 20 * sy + rect.minY)
            )

            // Pupil circle
            path.addEllipse(in: CGRect(
                x: 9 * sx + rect.minX,
                y: 9 * sy + rect.minY,
                width: 6 * sx,
                height: 6 * sy
            ))

            return path
        }
    }

    // MARK: - Eye Slash (Hide Password) Icon
    public struct EyeSlashShape: Shape {
        public func path(in rect: CGRect) -> Path {
            var path = EyeShape().path(in: rect)
            // Diagonal slash
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.15))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.85, y: rect.minY + rect.height * 0.85))
            return path
        }
    }

    // MARK: - Message / Info Icon
    public struct InfoBubbleShape: Shape {
        public func path(in rect: CGRect) -> Path {
            let sx = rect.width / 24.0
            let sy = rect.height / 24.0
            var path = Path()

            // Speech bubble circle
            path.addEllipse(in: CGRect(
                x: 3 * sx + rect.minX,
                y: 3 * sy + rect.minY,
                width: 18 * sx,
                height: 18 * sy
            ))

            // Info 'i' vertical line
            path.move(to: CGPoint(x: 12 * sx + rect.minX, y: 11 * sy + rect.minY))
            path.addLine(to: CGPoint(x: 12 * sx + rect.minX, y: 16 * sy + rect.minY))

            // Info 'i' dot
            path.addEllipse(in: CGRect(
                x: 11.2 * sx + rect.minX,
                y: 7.5 * sy + rect.minY,
                width: 1.6 * sx,
                height: 1.6 * sy
            ))

            return path
        }
    }
}

