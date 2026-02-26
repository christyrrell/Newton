import SwiftUI
import Foundation

struct CradleView: View {
    private let ballCount = 5
    private let ballRadius: CGFloat = 22
    private let stringLength: CGFloat = 220
    private let gravity: Double = 9.81
    private let damping: Double = 0.9995
    private let collisionTransfer: Double = 0.985

    @State private var angles: [Double] = [0, 0, 0, 0, 0]
    @State private var velocities: [Double] = [0, 0, 0, 0, 0]
    @State private var draggingBall: Int? = nil
    @State private var lastUpdate: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { timeline in
                Canvas { context, size in
                    drawCradle(context: context, size: size)
                }
                .background(
                    LinearGradient(
                        colors: [Color(white: 0.06), Color(white: 0.03)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .gesture(cradleDragGesture)
                .onChange(of: timeline.date) { _, newDate in
                    let dt = min(newDate.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    lastUpdate = newDate
                    if draggingBall == nil {
                        stepPhysics(dt: dt)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 16) {
                ForEach(presets, id: \.name) { preset in
                    Button(preset.name) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            angles = preset.angles
                            velocities = preset.velocities
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button("Stop") {
                    withAnimation(.easeOut(duration: 0.3)) {
                        velocities = Array(repeating: 0.0, count: ballCount)
                        angles = Array(repeating: 0.0, count: ballCount)
                    }
                }
                .buttonStyle(.bordered)

                Text("Drag any ball to start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private struct Preset {
        let name: String
        let angles: [Double]
        let velocities: [Double]
    }

    private let presets: [Preset] = [
        Preset(name: "1 Ball", angles: [-0.5, 0, 0, 0, 0], velocities: [0, 0, 0, 0, 0]),
        Preset(name: "2 Balls", angles: [-0.45, -0.45, 0, 0, 0], velocities: [0, 0, 0, 0, 0]),
        Preset(name: "3 Balls", angles: [-0.4, -0.4, -0.4, 0, 0], velocities: [0, 0, 0, 0, 0]),
        Preset(name: "Opposing", angles: [-0.5, 0, 0, 0, 0.5], velocities: [0, 0, 0, 0, 0]),
    ]

    // Geometry helpers
    private func ballCenter(index: Int, size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let topY = size.height * 0.15
        let spacing = ballRadius * 2 + 2
        let anchorX = centerX + CGFloat(index - ballCount / 2) * spacing
        let angle = CGFloat(angles[index])
        let bx = anchorX + stringLength * Foundation.sin(angle)
        let by = topY + stringLength * Foundation.cos(angle)
        return CGPoint(x: bx, y: by)
    }

    private var cradleDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // On first touch, find which ball is closest
                if draggingBall == nil {
                    let midX = value.startLocation.x
                    if midX < 200 {
                        draggingBall = 0
                    } else {
                        draggingBall = ballCount - 1
                    }
                }

                guard let ball = draggingBall else { return }

                // Convert drag to angle
                let dragX = value.translation.width
                let angle = Double(dragX) / Double(stringLength)
                let clampedAngle = max(-1.3, min(1.3, angle))

                angles[ball] = clampedAngle
                velocities[ball] = 0
            }
            .onEnded { _ in
                draggingBall = nil
            }
    }

    private func stepPhysics(dt: Double) {
        let substeps = 4
        let subDt = dt / Double(substeps)

        for _ in 0..<substeps {
            let g = gravity
            let L = Double(stringLength)

            // Update each pendulum
            for i in 0..<ballCount {
                let acceleration = -g / L * Foundation.sin(angles[i]) * 200
                velocities[i] += acceleration * subDt
                velocities[i] *= damping
                angles[i] += velocities[i] * subDt
            }

            // Collision detection
            let ballSpacingAngle = Double(ballRadius * 2 + 2) / Double(stringLength)

            for i in 0..<(ballCount - 1) {
                let gap = angles[i + 1] - angles[i]
                if gap < ballSpacingAngle * 0.02 {
                    // Elastic collision
                    let v1 = velocities[i]
                    let v2 = velocities[i + 1]
                    velocities[i] = v2 * collisionTransfer
                    velocities[i + 1] = v1 * collisionTransfer

                    // Separate
                    let overlap = ballSpacingAngle * 0.02 - gap
                    angles[i] -= overlap * 0.5
                    angles[i + 1] += overlap * 0.5
                }
            }
        }
    }

    private func drawCradle(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let centerX = w / 2
        let topY = h * 0.15
        let spacing = ballRadius * 2 + 2

        // Frame
        let frameWidth = CGFloat(ballCount) * spacing + 80
        let frameLeft = centerX - frameWidth / 2
        let frameRight = centerX + frameWidth / 2
        let frameBottom = topY + stringLength + ballRadius + 40

        // Frame top bar
        var topBar = Path()
        topBar.move(to: CGPoint(x: frameLeft + 15, y: topY - 15))
        topBar.addLine(to: CGPoint(x: frameRight - 15, y: topY - 15))
        context.stroke(topBar, with: .color(Color(white: 0.5)),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round))

        // Frame legs
        for (lx, dir) in [(frameLeft, CGFloat(-1)), (frameRight, CGFloat(1))] {
            var leg = Path()
            leg.move(to: CGPoint(x: lx + dir * -15, y: topY - 15))
            leg.addLine(to: CGPoint(x: lx + dir * 8, y: frameBottom))
            context.stroke(leg, with: .color(Color(white: 0.4)), lineWidth: 3)
        }

        // Base bar
        var baseBar = Path()
        baseBar.move(to: CGPoint(x: frameLeft - 8, y: frameBottom))
        baseBar.addLine(to: CGPoint(x: frameRight + 8, y: frameBottom))
        context.stroke(baseBar, with: .color(Color(white: 0.4)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // Draw each ball with two strings
        for i in 0..<ballCount {
            let anchorX = centerX + CGFloat(i - ballCount / 2) * spacing
            let angle = CGFloat(angles[i])

            let ballX = anchorX + stringLength * Foundation.sin(angle)
            let ballY = topY + stringLength * Foundation.cos(angle)

            // Two strings (V-shape for stability visual)
            let stringOffset: CGFloat = 8
            for dx in [-stringOffset, stringOffset] {
                var stringPath = Path()
                stringPath.move(to: CGPoint(x: anchorX + dx, y: topY - 12))
                stringPath.addLine(to: CGPoint(x: ballX, y: ballY))
                context.stroke(stringPath, with: .color(Color(white: 0.45, opacity: 0.7)),
                               lineWidth: 0.8)
            }

            // Ball shadow
            let shadowOffset: CGFloat = 3
            let shadowRect = CGRect(
                x: ballX - ballRadius + shadowOffset,
                y: ballY - ballRadius + shadowOffset,
                width: ballRadius * 2, height: ballRadius * 2
            )
            context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.4)))

            // Ball - chrome/metallic look
            let ballRect = CGRect(
                x: ballX - ballRadius, y: ballY - ballRadius,
                width: ballRadius * 2, height: ballRadius * 2
            )

            let metalGradient = Gradient(stops: [
                .init(color: Color(white: 0.90), location: 0.0),
                .init(color: Color(white: 0.70), location: 0.3),
                .init(color: Color(white: 0.45), location: 0.6),
                .init(color: Color(white: 0.25), location: 0.85),
                .init(color: Color(white: 0.35), location: 1.0),
            ])

            context.fill(
                Path(ellipseIn: ballRect),
                with: .radialGradient(
                    metalGradient,
                    center: CGPoint(x: ballX - ballRadius * 0.3, y: ballY - ballRadius * 0.3),
                    startRadius: 0,
                    endRadius: ballRadius * 1.1
                )
            )

            // Specular highlight
            let highlightRect = CGRect(
                x: ballX - ballRadius * 0.45,
                y: ballY - ballRadius * 0.55,
                width: ballRadius * 0.5,
                height: ballRadius * 0.35
            )
            context.fill(Path(ellipseIn: highlightRect), with: .color(.white.opacity(0.5)))

            // Rim light (bottom edge)
            let rimRect = CGRect(
                x: ballX - ballRadius * 0.3,
                y: ballY + ballRadius * 0.3,
                width: ballRadius * 0.6,
                height: ballRadius * 0.2
            )
            context.fill(Path(ellipseIn: rimRect), with: .color(.white.opacity(0.1)))
        }

        // Title
        let title = Text("Newton's Cradle")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
        context.draw(title, at: CGPoint(x: w / 2, y: h - 40))

        // Formula
        let formula = Text("Conservation: m\u{2081}v\u{2081} + m\u{2082}v\u{2082} = m\u{2081}v\u{2081}\u{2032} + m\u{2082}v\u{2082}\u{2032}")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.25))
        context.draw(formula, at: CGPoint(x: w / 2, y: h - 22))

        // Energy indicator
        let totalEnergy = (0..<ballCount).reduce(0.0) { sum, i in
            let ke = 0.5 * velocities[i] * velocities[i]
            let pe = gravity * Double(stringLength) * (1 - Foundation.cos(angles[i]))
            return sum + ke + pe
        }
        let energyBar = Text(String(format: "Total Energy: %.1f", totalEnergy))
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.3))
        context.draw(energyBar, at: CGPoint(x: w / 2, y: h - 6))
    }
}
