import SwiftUI
import Foundation

struct PrismView: View {
    @State private var prismAngle: Double = 60  // Apex angle in degrees
    @State private var beamY: Double = 0.4       // Vertical position (0-1)
    @State private var showLabels: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                drawScene(context: context, size: size)
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prism Angle: \(Int(prismAngle))\u{00B0}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $prismAngle, in: 30...80, step: 1)
                        .frame(width: 180)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Beam Position")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $beamY, in: 0.2...0.7)
                        .frame(width: 180)
                }

                Toggle("Labels", isOn: $showLabels)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Spacer()

                Button("Reset") {
                    withAnimation {
                        prismAngle = 60
                        beamY = 0.4
                        showLabels = true
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    // All geometry math uses Double to avoid CGFloat/Double ambiguity
    private func drawScene(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)

        // Prism geometry
        let cx = w * 0.45
        let cy = h * 0.55
        let ps = min(w, h) * 0.35
        let apexRad = prismAngle * .pi / 180.0

        let ax = cx, ay = cy - ps * 0.5                           // apex
        let blx = cx - ps * 0.5 * Foundation.tan(apexRad / 2), bly = cy + ps * 0.4  // base left
        let brx = cx + ps * 0.5 * Foundation.tan(apexRad / 2), bry = cy + ps * 0.4  // base right

        // Draw prism triangle
        var prismPath = Path()
        prismPath.move(to: CGPoint(x: ax, y: ay))
        prismPath.addLine(to: CGPoint(x: blx, y: bly))
        prismPath.addLine(to: CGPoint(x: brx, y: bry))
        prismPath.closeSubpath()

        context.fill(prismPath, with: .color(Color(white: 0.9, opacity: 0.18)))
        context.stroke(prismPath, with: .color(.white.opacity(0.6)), lineWidth: 1.5)

        // Incident beam - horizontal white light from left
        let beamStartX = w * 0.05
        let beamStartY = h * beamY

        // Intersect horizontal beam with left face (apex -> baseLeft)
        guard let hit = lineIntersect(
            x1: beamStartX, y1: beamStartY, x2: w, y2: beamStartY,
            x3: ax, y3: ay, x4: blx, y4: bly
        ) else { return }

        let hitT = (hit.y - ay) / (bly - ay)
        guard hitT > 0.05 && hitT < 0.95 else { return }

        // Draw white beam
        drawBeam(context: context, x1: beamStartX, y1: beamStartY,
                 x2: hit.x, y2: hit.y, color: .white, width: 3, glow: true)

        // Left face normal angle (pointing outward-left)
        let leftFaceAngle = Foundation.atan2(bly - ay, blx - ax)
        let normalAngle = leftFaceAngle - .pi / 2.0
        let angleBetween = abs(normalAngle) // angle of incidence for horizontal beam

        // Refract each wavelength through the prism
        let wavelengths = stride(from: 380.0, through: 700.0, by: 4.0)

        for wavelength in wavelengths {
            let n = refractiveIndex(wavelength: wavelength)
            let color = colorForWavelength(wavelength)

            // Snell's law at first surface
            let sinT1 = Foundation.sin(angleBetween)
            let sinT2 = sinT1 / n
            guard abs(sinT2) <= 1.0 else { continue }
            let theta2 = Foundation.asin(sinT2)

            // Direction inside prism
            let insideAngle = normalAngle + (normalAngle > 0 ? -theta2 : theta2)

            // Intersect with right face (apex -> baseRight)
            let rx = hit.x + Foundation.cos(insideAngle) * w
            let ry = hit.y + Foundation.sin(insideAngle) * w

            guard let exitPt = lineIntersect(
                x1: hit.x, y1: hit.y, x2: rx, y2: ry,
                x3: ax, y3: ay, x4: brx, y4: bry
            ) else { continue }

            let exitT = (exitPt.y - ay) / (bry - ay)
            guard exitT > 0.0 && exitT < 1.0 else { continue }

            // Refraction at second surface
            let rightFaceAngle = Foundation.atan2(bry - ay, brx - ax)
            let rightNormal = rightFaceAngle + .pi / 2.0
            let insideToNormal = insideAngle - rightNormal

            let sinExit = n * Foundation.sin(insideToNormal)
            guard abs(sinExit) <= 1.0 else { continue }
            let exitAngle = Foundation.asin(sinExit)
            let finalAngle = rightNormal + exitAngle

            // Project to screen edge
            let screenX = w * 0.95
            let rayLen = (screenX - exitPt.x) / Foundation.cos(finalAngle)
            let screenY = exitPt.y + Foundation.sin(finalAngle) * rayLen

            drawBeam(context: context, x1: exitPt.x, y1: exitPt.y,
                     x2: screenX, y2: screenY, color: color, width: 1.5, glow: false)
        }

        // Spectrum screen line
        let scrX = w * 0.94
        var screenPath = Path()
        screenPath.move(to: CGPoint(x: scrX, y: h * 0.1))
        screenPath.addLine(to: CGPoint(x: scrX, y: h * 0.9))
        context.stroke(screenPath, with: .color(.white.opacity(0.2)), lineWidth: 1)

        // Labels
        if showLabels {
            let whiteLabel = Text("White Light")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            context.draw(whiteLabel, at: CGPoint(x: beamStartX + 50, y: beamStartY - 15))

            for (name, wavelength) in namedColors {
                guard let screenY = projectWavelength(
                    wavelength: wavelength, normalAngle: normalAngle,
                    hitX: hit.x, hitY: hit.y,
                    ax: ax, ay: ay, brx: brx, bry: bry, screenX: w * 0.95, w: w
                ) else { continue }

                let label = Text(name)
                    .font(.system(size: 10))
                    .foregroundColor(colorForWavelength(wavelength))
                context.draw(label, at: CGPoint(x: w * 0.95 + 30, y: screenY))
            }

            let title = Text("Newton's Prism Experiment")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            context.draw(title, at: CGPoint(x: w * 0.5, y: 25))

            let formula = Text("Snell's Law: n\u{2081} sin \u{03B8}\u{2081} = n\u{2082} sin \u{03B8}\u{2082}")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            context.draw(formula, at: CGPoint(x: w * 0.5, y: h - 15))
        }
    }

    /// Trace a single wavelength through the prism and return the Y position on screen
    private func projectWavelength(
        wavelength: Double, normalAngle: Double,
        hitX: Double, hitY: Double,
        ax: Double, ay: Double, brx: Double, bry: Double,
        screenX: Double, w: Double
    ) -> Double? {
        let n = refractiveIndex(wavelength: wavelength)
        let sinT1 = Foundation.sin(abs(normalAngle))
        let sinT2 = sinT1 / n
        guard abs(sinT2) <= 1.0 else { return nil }
        let theta2 = Foundation.asin(sinT2)
        let insideAngle = normalAngle + (normalAngle > 0 ? -theta2 : theta2)

        let rx = hitX + Foundation.cos(insideAngle) * w
        let ry = hitY + Foundation.sin(insideAngle) * w

        guard let exitPt = lineIntersect(
            x1: hitX, y1: hitY, x2: rx, y2: ry,
            x3: ax, y3: ay, x4: brx, y4: bry
        ) else { return nil }

        let rightFaceAngle = Foundation.atan2(bry - ay, brx - ax)
        let rightNormal = rightFaceAngle + .pi / 2.0
        let insideToNormal = insideAngle - rightNormal
        let sinExit = n * Foundation.sin(insideToNormal)
        guard abs(sinExit) <= 1.0 else { return nil }
        let exitAngle = Foundation.asin(sinExit)
        let finalAngle = rightNormal + exitAngle
        let rayLen = (screenX - exitPt.x) / Foundation.cos(finalAngle)
        return exitPt.y + Foundation.sin(finalAngle) * rayLen
    }

    private func drawBeam(context: GraphicsContext, x1: Double, y1: Double,
                          x2: Double, y2: Double, color: Color, width: CGFloat, glow: Bool) {
        var path = Path()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))

        if glow {
            context.stroke(path, with: .color(color.opacity(0.15)), lineWidth: width + 8)
            context.stroke(path, with: .color(color.opacity(0.3)), lineWidth: width + 4)
        }
        context.stroke(path, with: .color(color), lineWidth: width)
    }
}

/// Line intersection using Double coordinates
private func lineIntersect(x1: Double, y1: Double, x2: Double, y2: Double,
                           x3: Double, y3: Double, x4: Double, y4: Double) -> (x: Double, y: Double)? {
    let d1x = x2 - x1, d1y = y2 - y1
    let d2x = x4 - x3, d2y = y4 - y3

    let denom = d1x * d2y - d1y * d2x
    guard abs(denom) > 0.0001 else { return nil }

    let t = ((x3 - x1) * d2y - (y3 - y1) * d2x) / denom
    let u = ((x3 - x1) * d1y - (y3 - y1) * d1x) / denom

    guard u >= 0 && u <= 1 else { return nil }

    return (x: x1 + t * d1x, y: y1 + t * d1y)
}
