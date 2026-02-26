import SwiftUI
import Foundation

struct CradleView: View {
    // Ball physics
    private let ballCount = 5
    private let ballRadius: CGFloat = 20
    private let stringLength: CGFloat = 200
    private let gravity: Double = 9.81
    private let damping: Double = 0.999
    private let collisionTransfer: Double = 0.98

    @State private var angles: [Double] = [0, 0, 0, 0, 0]
    @State private var velocities: [Double] = [0, 0, 0, 0, 0]
    @State private var isDragging: Int? = nil
    @State private var dragAngle: Double = 0
    @State private var isRunning = true
    @State private var selectedPreset = 0

    private let presets = [
        ("Single Ball", { () -> ([Double], [Double]) in ([-0.5, 0, 0, 0, 0], [0, 0, 0, 0, 0]) }),
        ("Two Balls", { () -> ([Double], [Double]) in ([-0.5, -0.5, 0, 0, 0], [0, 0, 0, 0, 0]) }),
        ("Three Balls", { () -> ([Double], [Double]) in ([-0.4, -0.4, -0.4, 0, 0], [0, 0, 0, 0, 0]) }),
        ("Opposing", { () -> ([Double], [Double]) in ([-0.5, 0, 0, 0, 0.5], [0, 0, 0, 0, 0]) }),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { timeline in
                Canvas { context, size in
                    updatePhysics()
                    drawCradle(context: context, size: size)
                }
                .background(
                    LinearGradient(
                        colors: [Color(white: 0.08), Color(white: 0.04)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(value: value)
                        }
                        .onEnded { _ in
                            isDragging = nil
                        }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 20) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                    Button(preset.0) {
                        let (a, v) = preset.1()
                        withAnimation(.easeOut(duration: 0.3)) {
                            angles = a
                            velocities = v
                        }
                        selectedPreset = index
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedPreset == index ? .blue : nil)
                }

                Spacer()

                Button("Stop") {
                    velocities = [0, 0, 0, 0, 0]
                    angles = [0, 0, 0, 0, 0]
                }
                .buttonStyle(.bordered)

                Text("Drag a ball to start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func handleDrag(value: DragGesture.Value) {
        // This is simplified - in a full implementation we'd track which ball was grabbed
        // For now, pull the leftmost ball
        let dragOffset = value.translation.width
        let angle = max(-1.2, min(0, -dragOffset / 200))
        angles[0] = angle
        velocities[0] = 0
    }

    private func updatePhysics() {
        guard isDragging == nil else { return }

        let dt = 1.0 / 120.0
        let g = gravity
        let L = Double(stringLength)

        // Update each pendulum
        for i in 0..<ballCount {
            // Gravity: angular acceleration = -g/L * sin(theta)
            let acceleration = -g / L * sin(angles[i])
            velocities[i] += acceleration * dt
            velocities[i] *= damping
            angles[i] += velocities[i] * dt
        }

        // Collision detection between adjacent balls
        for i in 0..<(ballCount - 1) {
            let ballSpacing = Double(ballRadius * 2 + 2)
            let x1 = Double(stringLength) * sin(angles[i])
            let x2 = Double(stringLength) * sin(angles[i + 1]) + ballSpacing

            if x1 > x2 - ballSpacing {
                // Elastic collision - swap velocities (Newton's Cradle behavior)
                let v1 = velocities[i]
                let v2 = velocities[i + 1]
                velocities[i] = v2 * collisionTransfer
                velocities[i + 1] = v1 * collisionTransfer
                // Separate balls
                let overlap = x1 - (x2 - ballSpacing)
                angles[i] -= overlap / (2 * L)
                angles[i + 1] += overlap / (2 * L)
            }
        }
    }

    private func drawCradle(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let centerX = w / 2
        let topY = h * 0.15
        let spacing = ballRadius * 2 + 2

        // Draw frame
        let frameWidth = CGFloat(ballCount) * spacing + 60
        let frameLeft = centerX - frameWidth / 2
        let frameRight = centerX + frameWidth / 2

        var framePath = Path()
        framePath.move(to: CGPoint(x: frameLeft, y: topY - 10))
        framePath.addLine(to: CGPoint(x: frameRight, y: topY - 10))
        context.stroke(framePath, with: .color(.gray.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round))

        // Frame supports
        for x in [frameLeft, frameRight] {
            var support = Path()
            support.move(to: CGPoint(x: x, y: topY - 10))
            support.addLine(to: CGPoint(x: x + (x < centerX ? -15 : 15), y: topY + stringLength + 60))
            context.stroke(support, with: .color(.gray.opacity(0.5)), lineWidth: 2)
        }

        // Draw each ball
        for i in 0..<ballCount {
            let anchorX = centerX + CGFloat(i - ballCount / 2) * spacing
            let angle = angles[i]

            let ballX = anchorX + stringLength * CGFloat(sin(angle))
            let ballY = topY + stringLength * CGFloat(cos(angle))

            // String
            var stringPath = Path()
            stringPath.move(to: CGPoint(x: anchorX, y: topY))
            stringPath.addLine(to: CGPoint(x: ballX, y: ballY))
            context.stroke(stringPath, with: .color(.gray.opacity(0.6)), lineWidth: 1)

            // Ball shadow
            let shadowRect = CGRect(
                x: ballX - ballRadius + 3,
                y: ballY - ballRadius + 3,
                width: ballRadius * 2,
                height: ballRadius * 2
            )
            context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.3)))

            // Ball with metallic gradient
            let ballRect = CGRect(
                x: ballX - ballRadius,
                y: ballY - ballRadius,
                width: ballRadius * 2,
                height: ballRadius * 2
            )

            let gradient = Gradient(colors: [
                Color(white: 0.85),
                Color(white: 0.55),
                Color(white: 0.3)
            ])

            context.fill(
                Path(ellipseIn: ballRect),
                with: .radialGradient(
                    gradient,
                    center: CGPoint(x: ballX - 5, y: ballY - 5),
                    startRadius: 0,
                    endRadius: ballRadius
                )
            )

            // Highlight
            let highlightRect = CGRect(
                x: ballX - ballRadius * 0.4,
                y: ballY - ballRadius * 0.5,
                width: ballRadius * 0.5,
                height: ballRadius * 0.3
            )
            context.fill(
                Path(ellipseIn: highlightRect),
                with: .color(.white.opacity(0.4))
            )
        }

        // Title
        let title = Text("Newton's Cradle")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w / 2, y: h - 25))

        let formula = Text("Conservation of Momentum: m\u{2081}v\u{2081} = m\u{2082}v\u{2082}")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.3))
        context.draw(formula, at: CGPoint(x: w / 2, y: h - 10))
    }
}
