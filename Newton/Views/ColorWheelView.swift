import SwiftUI
import Foundation

/// Newton's Color Wheel - Newton was the first to arrange the visible spectrum
/// into a circle, predicting that mixing all colors would produce white.
struct ColorWheelView: View {
    @State private var rotationAngle: Double = 0
    @State private var isSpinning: Bool = false
    @State private var spinSpeed: Double = 0
    @State private var showSectors: Bool = true
    @State private var showWavelengths: Bool = true
    @State private var mixingProgress: Double = 0

    private let spinDecay: Double = 0.995

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    drawColorWheel(context: context, size: size)
                }
                .background(Color(white: 0.04))
                .onChange(of: timeline.date) { _, _ in
                    updateSpin()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            HStack(spacing: 20) {
                Button(isSpinning ? "Stop" : "Spin") {
                    if isSpinning {
                        spinSpeed = 0
                        isSpinning = false
                    } else {
                        spinSpeed = 15.0
                        isSpinning = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])

                if isSpinning {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spin Speed")
                            .font(.caption).foregroundStyle(.secondary)
                        Slider(value: $spinSpeed, in: 0...30)
                            .frame(width: 150)
                    }
                }

                Toggle("Sectors", isOn: $showSectors)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Wavelengths", isOn: $showWavelengths)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Spacer()

                Text("Spin fast to see colors merge toward white")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func updateSpin() {
        if isSpinning {
            rotationAngle += spinSpeed
            if spinSpeed > 0.01 {
                spinSpeed *= spinDecay
            }
            if spinSpeed < 0.05 {
                spinSpeed = 0
                isSpinning = false
            }
        }

        // Mixing progress is proportional to spin speed
        let targetMix = min(1.0, spinSpeed / 10.0)
        mixingProgress += (targetMix - mixingProgress) * 0.05
    }

    private func drawColorWheel(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)
        let cx = w * 0.5
        let cy = h * 0.48
        let outerR = min(w, h) * 0.35
        let innerR = outerR * 0.3

        // Newton's 7 spectral colors with their angular positions
        let colors: [(name: String, wavelength: Double, hue: Double)] = [
            ("Red", 680, 0.0),
            ("Orange", 610, 30.0),
            ("Yellow", 580, 60.0),
            ("Green", 530, 120.0),
            ("Blue", 470, 210.0),
            ("Indigo", 435, 260.0),
            ("Violet", 400, 300.0),
        ]

        let sectorAngle = 360.0 / Double(colors.count)

        // White disk behind the wheel (visible as colors fade)
        if mixingProgress > 0.05 {
            let whiteRect = CGRect(x: cx - outerR, y: cy - outerR,
                                    width: outerR * 2, height: outerR * 2)
            context.fill(Path(ellipseIn: whiteRect),
                         with: .color(Color(white: 0.8, opacity: mixingProgress * 0.9)))
        }

        // Draw the wheel
        for (i, colorInfo) in colors.enumerated() {
            let startAngle = Double(i) * sectorAngle + rotationAngle
            let endAngle = startAngle + sectorAngle

            let spectralColor = colorForWavelength(colorInfo.wavelength)

            // As spin increases, colors fade toward gray (simulating blending)
            let colorOpacity = max(0.15, 1.0 - mixingProgress * 0.85)

            // Draw sector
            var sector = Path()
            sector.move(to: CGPoint(x: cx, y: cy))
            sector.addArc(center: CGPoint(x: cx, y: cy),
                          radius: CGFloat(outerR),
                          startAngle: .degrees(startAngle - 90),
                          endAngle: .degrees(endAngle - 90),
                          clockwise: false)
            sector.closeSubpath()

            context.fill(sector, with: .color(spectralColor.opacity(colorOpacity)))

            // Sector borders (when not spinning fast)
            if showSectors && mixingProgress < 0.5 {
                context.stroke(sector, with: .color(.white.opacity(0.2 * (1 - mixingProgress * 2))),
                               lineWidth: 1)
            }

            // Labels (when not spinning fast)
            if showWavelengths && mixingProgress < 0.3 {
                let midAngle = (startAngle + sectorAngle / 2 - 90) * .pi / 180.0
                let labelR = outerR * 0.7
                let labelX = cx + Foundation.cos(midAngle) * labelR
                let labelY = cy + Foundation.sin(midAngle) * labelR

                let opacity = 1.0 - mixingProgress * 3
                let label = Text(colorInfo.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(max(0, opacity)))
                context.draw(label, at: CGPoint(x: labelX, y: labelY))

                let wlLabel = Text("\(Int(colorInfo.wavelength)) nm")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(max(0, opacity * 0.6)))
                context.draw(wlLabel, at: CGPoint(x: labelX, y: labelY + 14))
            }
        }

        // Center circle (shows the "mixed" result)
        let centerColor: Color
        if mixingProgress > 0.1 {
            let brightness = 0.3 + mixingProgress * 0.55
            centerColor = Color(white: brightness)
        } else {
            centerColor = Color(white: 0.15)
        }

        let centerRect = CGRect(x: cx - innerR, y: cy - innerR,
                                 width: innerR * 2, height: innerR * 2)
        context.fill(Path(ellipseIn: centerRect), with: .color(centerColor))
        context.stroke(Path(ellipseIn: centerRect),
                       with: .color(.white.opacity(0.3)), lineWidth: 1)

        // Center label
        if mixingProgress > 0.5 {
            let whiteLabel = Text("White")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black.opacity(mixingProgress))
            context.draw(whiteLabel, at: CGPoint(x: cx, y: cy))
        }

        // Outer ring decoration
        let outerRingRect = CGRect(x: cx - outerR - 2, y: cy - outerR - 2,
                                    width: (outerR + 2) * 2, height: (outerR + 2) * 2)
        context.stroke(Path(ellipseIn: outerRingRect),
                       with: .color(.white.opacity(0.2)), lineWidth: 1)

        // Title
        let title = Text("Newton's Colour Circle")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 25))

        // Explanatory text
        let explanation: String
        if mixingProgress > 0.5 {
            explanation = "All spectral colors combine to produce white light"
        } else if isSpinning {
            explanation = "As the wheel spins faster, colors merge..."
        } else {
            explanation = "Newton arranged the 7 spectral colors in a circle (1704)"
        }
        let expText = Text(explanation)
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.35))
        context.draw(expText, at: CGPoint(x: w * 0.5, y: h - 15))

        // Speed indicator
        if isSpinning {
            let speedText = Text(String(format: "%.0f rpm", spinSpeed * 10))
                .font(.system(size: 10, weight: .medium).monospaced())
                .foregroundColor(.white.opacity(0.4))
            context.draw(speedText, at: CGPoint(x: cx, y: cy + outerR + 25))
        }
    }

}
