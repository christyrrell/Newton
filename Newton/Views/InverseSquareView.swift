import SwiftUI
import Foundation

/// Interactive demonstration of the Inverse Square Law
/// Shows how gravitational (or light) intensity decreases with the square of distance
struct InverseSquareView: View {
    @State private var sourceX: Double = 0.2
    @State private var showWavefronts: Bool = true
    @State private var showGraph: Bool = true
    @State private var showAreas: Bool = true
    @State private var animationPhase: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let _ = timeline.date
                Canvas { context, size in
                    animationPhase += 1.0 / 60.0
                    drawScene(context: context, size: size)
                }
                .background(Color(white: 0.03))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            HStack(spacing: 20) {
                Toggle("Wavefronts", isOn: $showWavefronts)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Area Panels", isOn: $showAreas)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Force Graph", isOn: $showGraph)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Spacer()
            }
            .padding()
        }
    }

    private func drawScene(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)

        let srcX = w * 0.12
        let srcY = h * 0.45

        // Pulsing source
        let pulseR = 12.0 + 3.0 * Foundation.sin(animationPhase * 3)
        for r in stride(from: pulseR + 8, through: pulseR, by: -2.0) {
            let opacity = 0.1 * (1.0 - (r - pulseR) / 8.0)
            let rect = CGRect(x: srcX - r, y: srcY - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.yellow.opacity(opacity)))
        }
        let srcRect = CGRect(x: srcX - 8, y: srcY - 8, width: 16, height: 16)
        context.fill(Path(ellipseIn: srcRect),
                     with: .radialGradient(
                        Gradient(colors: [.white, .yellow]),
                        center: CGPoint(x: srcX, y: srcY),
                        startRadius: 0, endRadius: 8))

        let srcLabel = Text("M")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.yellow)
        context.draw(srcLabel, at: CGPoint(x: srcX, y: srcY + 20))

        // Expanding wavefronts (concentric circles)
        if showWavefronts {
            let maxR = w * 0.9
            let waveSpeed = 80.0
            let waveCount = 8
            for i in 0..<waveCount {
                let phase = Foundation.fmod(animationPhase * waveSpeed + Double(i) * maxR / Double(waveCount), maxR)
                let opacity = max(0, 0.3 * (1.0 - phase / maxR))
                var circle = Path()
                circle.addArc(center: CGPoint(x: srcX, y: srcY),
                              radius: CGFloat(phase),
                              startAngle: .degrees(-60), endAngle: .degrees(60),
                              clockwise: false)
                context.stroke(circle, with: .color(.cyan.opacity(opacity)),
                               lineWidth: 1)
            }
        }

        // Radiating lines from source
        let lineCount = 12
        let spread = 50.0  // degrees
        for i in 0..<lineCount {
            let angle = -spread + Double(i) * (2 * spread) / Double(lineCount - 1)
            let rad = angle * .pi / 180.0
            let endX = srcX + Foundation.cos(rad) * w
            let endY = srcY + Foundation.sin(rad) * w

            var ray = Path()
            ray.move(to: CGPoint(x: srcX, y: srcY))
            ray.addLine(to: CGPoint(x: endX, y: endY))
            context.stroke(ray, with: .color(.yellow.opacity(0.08)), lineWidth: 0.5)
        }

        // Distance panels showing area increase
        if showAreas {
            let distances: [(d: Double, label: String)] = [
                (1.0, "r"), (2.0, "2r"), (3.0, "3r")
            ]

            let unitDist = w * 0.18

            for (d, label) in distances {
                let panelX = srcX + d * unitDist
                let halfSpread = d * unitDist * Foundation.tan(spread * .pi / 180.0)
                let panelHalfH = min(halfSpread * 0.3, h * 0.35)

                // Panel rectangle
                var panel = Path()
                panel.move(to: CGPoint(x: panelX, y: srcY - panelHalfH))
                panel.addLine(to: CGPoint(x: panelX, y: srcY + panelHalfH))
                context.stroke(panel, with: .color(.white.opacity(0.6)),
                               style: StrokeStyle(lineWidth: 2, dash: d > 1 ? [4, 2] : []))

                // Area indicator (square)
                let areaSize = panelHalfH * 0.5
                let areaRect = CGRect(x: panelX - areaSize / 2,
                                       y: srcY - panelHalfH - areaSize - 15,
                                       width: areaSize, height: areaSize)
                let areaOpacity = 1.0 / (d * d)
                context.fill(Path(areaRect),
                             with: .color(.orange.opacity(areaOpacity * 0.5)))
                context.stroke(Path(areaRect),
                               with: .color(.orange.opacity(0.7)), lineWidth: 1)

                // Intensity shading on the panel line
                let intensityColor = Color.yellow.opacity(areaOpacity * 0.4)
                let bandWidth = 8.0
                let bandRect = CGRect(x: panelX - bandWidth / 2,
                                       y: srcY - panelHalfH,
                                       width: bandWidth,
                                       height: panelHalfH * 2)
                context.fill(Path(bandRect), with: .color(intensityColor))

                // Labels
                let distLabel = Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                context.draw(distLabel, at: CGPoint(x: panelX, y: srcY + panelHalfH + 15))

                let intensityStr = String(format: "F = F\u{2080}/%g", d * d)
                let intLabel = Text(intensityStr)
                    .font(.system(size: 10))
                    .foregroundColor(.orange.opacity(0.8))
                context.draw(intLabel, at: CGPoint(x: panelX, y: srcY + panelHalfH + 30))

                // Area label
                let areaStr = String(format: "%.0f\u{00D7} area", d * d)
                let aLabel = Text(areaStr)
                    .font(.system(size: 9))
                    .foregroundColor(.orange.opacity(0.6))
                context.draw(aLabel, at: CGPoint(x: panelX,
                                                  y: srcY - panelHalfH - areaSize - 25))
            }
        }

        // Force vs distance graph (bottom right)
        if showGraph {
            let graphX = w * 0.62
            let graphY = h * 0.62
            let graphW = w * 0.34
            let graphH = h * 0.32

            // Graph background
            let graphRect = CGRect(x: graphX, y: graphY, width: graphW, height: graphH)
            context.fill(Path(graphRect), with: .color(Color(white: 0.06)))
            context.stroke(Path(graphRect), with: .color(.white.opacity(0.2)), lineWidth: 0.5)

            // Axes
            var xAxis = Path()
            xAxis.move(to: CGPoint(x: graphX + 30, y: graphY + graphH - 25))
            xAxis.addLine(to: CGPoint(x: graphX + graphW - 10, y: graphY + graphH - 25))
            context.stroke(xAxis, with: .color(.white.opacity(0.4)), lineWidth: 1)

            var yAxis = Path()
            yAxis.move(to: CGPoint(x: graphX + 30, y: graphY + 10))
            yAxis.addLine(to: CGPoint(x: graphX + 30, y: graphY + graphH - 25))
            context.stroke(yAxis, with: .color(.white.opacity(0.4)), lineWidth: 1)

            // Labels
            let xLabel = Text("Distance (r)")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
            context.draw(xLabel, at: CGPoint(x: graphX + graphW / 2 + 10, y: graphY + graphH - 8))

            let yLabel = Text("Force (F)")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
            context.draw(yLabel, at: CGPoint(x: graphX + 12, y: graphY + 15))

            // 1/r^2 curve
            let plotLeft = graphX + 32
            let plotRight = graphX + graphW - 12
            let plotTop = graphY + 12
            let plotBottom = graphY + graphH - 27

            var curve = Path()
            var started = false
            for px in stride(from: plotLeft, through: plotRight, by: 1) {
                let t = (px - plotLeft) / (plotRight - plotLeft)  // 0 to 1
                let r = 0.3 + t * 3.0  // r from 0.3 to 3.3
                let f = 1.0 / (r * r)  // inverse square
                let normalizedF = min(1.0, f / (1.0 / (0.3 * 0.3)))  // normalize

                let py = plotBottom - normalizedF * (plotBottom - plotTop)

                if !started {
                    curve.move(to: CGPoint(x: px, y: py))
                    started = true
                } else {
                    curve.addLine(to: CGPoint(x: px, y: py))
                }
            }
            context.stroke(curve, with: .color(.orange), lineWidth: 2)

            // Comparison: 1/r curve (dashed)
            var linearCurve = Path()
            started = false
            for px in stride(from: plotLeft, through: plotRight, by: 1) {
                let t = (px - plotLeft) / (plotRight - plotLeft)
                let r = 0.3 + t * 3.0
                let f = 1.0 / r
                let normalizedF = min(1.0, f / (1.0 / 0.3))

                let py = plotBottom - normalizedF * (plotBottom - plotTop)
                if !started {
                    linearCurve.move(to: CGPoint(x: px, y: py))
                    started = true
                } else {
                    linearCurve.addLine(to: CGPoint(x: px, y: py))
                }
            }
            context.stroke(linearCurve, with: .color(.cyan.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

            // Legend
            let legendY = graphY + 18
            var legendLine1 = Path()
            legendLine1.move(to: CGPoint(x: graphX + graphW - 90, y: legendY))
            legendLine1.addLine(to: CGPoint(x: graphX + graphW - 70, y: legendY))
            context.stroke(legendLine1, with: .color(.orange), lineWidth: 2)
            let leg1 = Text("1/r\u{00B2}")
                .font(.system(size: 9))
                .foregroundColor(.orange)
            context.draw(leg1, at: CGPoint(x: graphX + graphW - 55, y: legendY))

            var legendLine2 = Path()
            legendLine2.move(to: CGPoint(x: graphX + graphW - 90, y: legendY + 14))
            legendLine2.addLine(to: CGPoint(x: graphX + graphW - 70, y: legendY + 14))
            context.stroke(legendLine2, with: .color(.cyan.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            let leg2 = Text("1/r")
                .font(.system(size: 9))
                .foregroundColor(.cyan.opacity(0.5))
            context.draw(leg2, at: CGPoint(x: graphX + graphW - 55, y: legendY + 14))

            let graphTitle = Text("Force vs Distance")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            context.draw(graphTitle, at: CGPoint(x: graphX + graphW / 2 + 10, y: graphY + 8))
        }

        // Title and formula
        let title = Text("The Inverse Square Law")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 20))

        let formula = Text("F = G \u{00B7} m\u{2081}m\u{2082} / r\u{00B2}  \u{2014}  Intensity \u{221D} 1/r\u{00B2}")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.3))
        context.draw(formula, at: CGPoint(x: w * 0.5, y: h - 15))
    }
}
