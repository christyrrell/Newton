import SwiftUI
import Foundation

/// Simulates the famous "falling apple" moment with a gravitational field visualization
struct FallingAppleView: View {
    @State private var appleY: Double = 0
    @State private var appleVelocity: Double = 0
    @State private var appleDropped: Bool = false
    @State private var appleOnGround: Bool = false
    @State private var showField: Bool = true
    @State private var showForceArrows: Bool = true
    @State private var earthMass: Double = 5.0
    @State private var bounceCount: Int = 0
    @State private var time: Double = 0

    private let appleStartY: Double = 0.12
    private let groundLevel: Double = 0.78
    private let treeX: Double = 0.35
    private let gravity: Double = 400.0
    private let restitution: Double = 0.5

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let _ = timeline.date
                Canvas { context, size in
                    if appleDropped && !appleOnGround {
                        updateApple(size: size)
                    }
                    time += 1.0 / 60.0
                    drawScene(context: context, size: size)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.02, blue: 0.08),
                            Color(red: 0.05, green: 0.05, blue: 0.12),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])
            .onTapGesture {
                if !appleDropped {
                    appleDropped = true
                } else {
                    resetApple()
                }
            }

            HStack(spacing: 20) {
                Button(appleDropped ? "Reset" : "Drop Apple") {
                    if appleDropped {
                        resetApple()
                    } else {
                        appleDropped = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])

                VStack(alignment: .leading, spacing: 4) {
                    Text("Earth Mass: \(String(format: "%.1f", earthMass))x")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $earthMass, in: 1...10)
                        .frame(width: 150)
                }

                Toggle("Field Lines", isOn: $showField)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Force Arrows", isOn: $showForceArrows)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Spacer()

                Text("Click canvas or press Space to drop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func resetApple() {
        appleY = 0
        appleVelocity = 0
        appleDropped = false
        appleOnGround = false
        bounceCount = 0
    }

    private func updateApple(size: CGSize) {
        let dt = 1.0 / 60.0
        let g = gravity * earthMass / 5.0

        appleVelocity += g * dt
        appleY += appleVelocity * dt

        let maxY = (groundLevel - appleStartY) * Double(size.height)
        if appleY >= maxY {
            appleY = maxY
            appleVelocity = -appleVelocity * restitution
            bounceCount += 1
            if bounceCount > 5 || abs(appleVelocity) < 10 {
                appleOnGround = true
                appleVelocity = 0
            }
        }
    }

    private func drawScene(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)
        let gndY = h * groundLevel

        // Gravitational field visualization
        if showField {
            let earthCenterX = w * 0.5
            let earthCenterY = h * 1.3  // Below visible area (earth is below ground)

            let gridSpacing = 40.0
            for gx in stride(from: gridSpacing / 2, through: w, by: gridSpacing) {
                for gy in stride(from: gridSpacing / 2, through: gndY - 10, by: gridSpacing) {
                    let dx = gx - earthCenterX
                    let dy = gy - earthCenterY
                    let dist = Foundation.sqrt(dx * dx + dy * dy)
                    let strength = min(1.0, 500.0 * earthMass / (dist * dist) * 100)

                    // Arrow pointing toward earth center (downward)
                    let arrowLen = min(15.0, strength * 15)
                    let dirX = dx / dist
                    let dirY = dy / dist

                    let startX = gx - dirX * arrowLen * 0.5
                    let startY = gy - dirY * arrowLen * 0.5
                    let endX = gx + dirX * arrowLen * 0.5
                    let endY = gy + dirY * arrowLen * 0.5

                    var arrow = Path()
                    arrow.move(to: CGPoint(x: startX, y: startY))
                    arrow.addLine(to: CGPoint(x: endX, y: endY))

                    let opacity = min(0.4, strength * 0.4)
                    let color = Color(red: 0.3, green: 0.5, blue: 1.0)
                    context.stroke(arrow, with: .color(color.opacity(opacity)), lineWidth: 1)

                    // Arrowhead
                    let headLen = arrowLen * 0.3
                    let perpX = -dirY
                    let perpY = dirX
                    var head = Path()
                    head.move(to: CGPoint(x: endX, y: endY))
                    head.addLine(to: CGPoint(x: endX - dirX * headLen + perpX * headLen * 0.4,
                                             y: endY - dirY * headLen + perpY * headLen * 0.4))
                    head.move(to: CGPoint(x: endX, y: endY))
                    head.addLine(to: CGPoint(x: endX - dirX * headLen - perpX * headLen * 0.4,
                                             y: endY - dirY * headLen - perpY * headLen * 0.4))
                    context.stroke(head, with: .color(color.opacity(opacity)), lineWidth: 1)
                }
            }
        }

        // Ground
        let groundRect = CGRect(x: 0, y: gndY, width: w, height: h - gndY)
        let groundGrad = Gradient(colors: [
            Color(red: 0.15, green: 0.3, blue: 0.1),
            Color(red: 0.1, green: 0.2, blue: 0.05)
        ])
        context.fill(Path(groundRect), with: .linearGradient(
            groundGrad, startPoint: CGPoint(x: 0, y: gndY),
            endPoint: CGPoint(x: 0, y: h)))

        // Tree trunk
        let trunkX = w * treeX
        let trunkWidth = 20.0
        let trunkRect = CGRect(x: trunkX - trunkWidth / 2, y: gndY - 180,
                                width: trunkWidth, height: 185)
        context.fill(Path(trunkRect), with: .color(Color(red: 0.35, green: 0.2, blue: 0.1)))

        // Tree canopy (layered circles)
        let canopyColors = [
            Color(red: 0.15, green: 0.45, blue: 0.15),
            Color(red: 0.2, green: 0.55, blue: 0.2),
            Color(red: 0.18, green: 0.5, blue: 0.18),
        ]
        let canopyPositions: [(dx: Double, dy: Double, r: Double)] = [
            (0, -220, 70), (-40, -200, 55), (40, -200, 55),
            (-20, -250, 50), (20, -250, 50), (0, -270, 45),
        ]
        for (i, pos) in canopyPositions.enumerated() {
            let rect = CGRect(
                x: trunkX + pos.dx - pos.r,
                y: gndY + pos.dy - pos.r,
                width: pos.r * 2, height: pos.r * 2
            )
            context.fill(Path(ellipseIn: rect),
                         with: .color(canopyColors[i % canopyColors.count]))
        }

        // Apple
        let appleX = trunkX + 45
        let appleBaseY = h * appleStartY
        let currentAppleY = appleBaseY + appleY
        let appleSize = 14.0

        // Apple (red circle with highlight)
        let appleRect = CGRect(x: appleX - appleSize / 2, y: currentAppleY - appleSize / 2,
                                width: appleSize, height: appleSize)
        context.fill(Path(ellipseIn: appleRect),
                     with: .radialGradient(
                        Gradient(colors: [Color(red: 1, green: 0.2, blue: 0.15),
                                          Color(red: 0.7, green: 0.1, blue: 0.05)]),
                        center: CGPoint(x: appleX - 2, y: currentAppleY - 2),
                        startRadius: 0, endRadius: appleSize / 2))

        // Apple stem
        var stem = Path()
        stem.move(to: CGPoint(x: appleX, y: currentAppleY - appleSize / 2))
        stem.addLine(to: CGPoint(x: appleX + 2, y: currentAppleY - appleSize / 2 - 5))
        context.stroke(stem, with: .color(Color(red: 0.3, green: 0.2, blue: 0.05)), lineWidth: 1.5)

        // Branch line to apple (only when not dropped)
        if !appleDropped {
            var branch = Path()
            branch.move(to: CGPoint(x: trunkX + 10, y: gndY - 190))
            branch.addQuadCurve(to: CGPoint(x: appleX, y: currentAppleY - appleSize / 2 - 5),
                                control: CGPoint(x: appleX - 10, y: gndY - 200))
            context.stroke(branch, with: .color(Color(red: 0.3, green: 0.18, blue: 0.08)), lineWidth: 2)
        }

        // Force arrow on apple
        if showForceArrows && appleDropped && !appleOnGround {
            let forceLen = 30.0 * earthMass / 5.0
            var forceArrow = Path()
            forceArrow.move(to: CGPoint(x: appleX, y: currentAppleY))
            forceArrow.addLine(to: CGPoint(x: appleX, y: currentAppleY + forceLen))
            context.stroke(forceArrow, with: .color(.yellow), lineWidth: 2)

            // Arrowhead
            var head = Path()
            head.move(to: CGPoint(x: appleX, y: currentAppleY + forceLen))
            head.addLine(to: CGPoint(x: appleX - 4, y: currentAppleY + forceLen - 8))
            head.move(to: CGPoint(x: appleX, y: currentAppleY + forceLen))
            head.addLine(to: CGPoint(x: appleX + 4, y: currentAppleY + forceLen - 8))
            context.stroke(head, with: .color(.yellow), lineWidth: 2)

            let fLabel = Text("F = mg")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.yellow.opacity(0.9))
            context.draw(fLabel, at: CGPoint(x: appleX + 30, y: currentAppleY + forceLen / 2))
        }

        // Newton sitting under tree
        let newtonX = trunkX + 80
        let newtonY = gndY

        // Simple stick figure sitting
        // Head
        let headRect = CGRect(x: newtonX - 8, y: newtonY - 55, width: 16, height: 16)
        context.fill(Path(ellipseIn: headRect), with: .color(Color(red: 0.9, green: 0.8, blue: 0.7)))

        // Body
        var body = Path()
        body.move(to: CGPoint(x: newtonX, y: newtonY - 39))
        body.addLine(to: CGPoint(x: newtonX, y: newtonY - 15))
        context.stroke(body, with: .color(.white.opacity(0.7)), lineWidth: 2)

        // Legs (sitting)
        var legs = Path()
        legs.move(to: CGPoint(x: newtonX, y: newtonY - 15))
        legs.addLine(to: CGPoint(x: newtonX + 12, y: newtonY - 5))
        legs.addLine(to: CGPoint(x: newtonX + 5, y: newtonY))
        context.stroke(legs, with: .color(.white.opacity(0.7)), lineWidth: 2)

        // Newton label
        if appleOnGround {
            let eureka = Text("Eureka!")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.yellow)
            context.draw(eureka, at: CGPoint(x: newtonX + 10, y: newtonY - 70))
        }

        // Info text
        let title = Text("The Falling Apple")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 20))

        // Speed and distance info
        if appleDropped {
            let distance = appleY / (h * (groundLevel - appleStartY)) * 5.0 // Scale to ~5 meters
            let speed = abs(appleVelocity) / (h * (groundLevel - appleStartY)) * 5.0 * 60

            let info = Text(String(format: "Height fallen: %.1fm  |  Speed: %.1f m/s  |  g = %.1f m/s\u{00B2}",
                                   distance, speed, 9.81 * earthMass / 5.0))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            context.draw(info, at: CGPoint(x: w * 0.5, y: h - 15))
        }

        // Quote
        if !appleDropped {
            let quote = Text("\u{201C}If I have seen further, it is by standing on the shoulders of giants.\u{201D}")
                .font(.system(size: 11, weight: .light).italic())
                .foregroundColor(.white.opacity(0.3))
            context.draw(quote, at: CGPoint(x: w * 0.5, y: h - 15))
        }
    }
}
