import SwiftUI
import Foundation

/// Interactive demonstration of Newton's Three Laws of Motion
struct ThreeLawsView: View {
    @State private var selectedLaw = 0

    // Law 1: Inertia
    @State private var puckX: Double = 0.15
    @State private var puckVX: Double = 0
    @State private var frictionOn: Bool = false
    @State private var puckLaunched: Bool = false

    // Law 2: F = ma
    @State private var forceMagnitude: Double = 100
    @State private var objectMass: Double = 5.0
    @State private var law2X: Double = 0.1
    @State private var law2VX: Double = 0
    @State private var law2Pushing: Bool = false

    // Law 3: Action-Reaction
    @State private var law3Time: Double = 0
    @State private var ballAX: Double = 0.35
    @State private var ballBX: Double = 0.65
    @State private var ballAVX: Double = 2.0
    @State private var ballBVX: Double = -2.0
    @State private var collided: Bool = false
    @State private var showForces: Bool = true

    private let laws = [
        "First Law: Inertia",
        "Second Law: F = ma",
        "Third Law: Action-Reaction"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Law selector tabs
            Picker("Law", selection: $selectedLaw) {
                ForEach(0..<3, id: \.self) { i in
                    Text(laws[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: selectedLaw) { _, _ in
                resetCurrentLaw()
            }

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let _ = timeline.date
                Canvas { context, size in
                    updatePhysics(size: size)
                    switch selectedLaw {
                    case 0: drawLaw1(context: context, size: size)
                    case 1: drawLaw2(context: context, size: size)
                    case 2: drawLaw3(context: context, size: size)
                    default: break
                    }
                }
                .background(Color(white: 0.04))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal])

            // Law-specific controls
            HStack(spacing: 16) {
                switch selectedLaw {
                case 0:
                    Button(puckLaunched ? "Reset" : "Push Puck") {
                        if puckLaunched {
                            resetCurrentLaw()
                        } else {
                            puckVX = 3.0
                            puckLaunched = true
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Toggle("Friction", isOn: $frictionOn)
                        .toggleStyle(.checkbox)
                        .font(.caption)

                    Text(frictionOn
                         ? "With friction, the puck slows and stops."
                         : "Without friction, the puck moves forever (Newton's 1st Law).")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                case 1:
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force: \(Int(forceMagnitude)) N")
                            .font(.caption).foregroundStyle(.secondary)
                        Slider(value: $forceMagnitude, in: 10...300, step: 10)
                            .frame(width: 150)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mass: \(String(format: "%.1f", objectMass)) kg")
                            .font(.caption).foregroundStyle(.secondary)
                        Slider(value: $objectMass, in: 1...20, step: 0.5)
                            .frame(width: 150)
                    }

                    Button(law2Pushing ? "Release" : "Apply Force") {
                        law2Pushing.toggle()
                        if !law2Pushing && law2VX < 0.01 {
                            resetCurrentLaw()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    let accel = forceMagnitude / objectMass
                    Text(String(format: "a = F/m = %.1f/%.1f = %.1f m/s\u{00B2}", forceMagnitude, objectMass, accel))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                case 2:
                    Toggle("Show Forces", isOn: $showForces)
                        .toggleStyle(.checkbox)
                        .font(.caption)

                    Button("Reset Collision") {
                        resetCurrentLaw()
                    }
                    .buttonStyle(.bordered)

                    Text("Equal and opposite forces during collision")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                default:
                    EmptyView()
                }

                Spacer()
            }
            .padding()
        }
    }

    private func resetCurrentLaw() {
        switch selectedLaw {
        case 0:
            puckX = 0.15
            puckVX = 0
            puckLaunched = false
        case 1:
            law2X = 0.1
            law2VX = 0
            law2Pushing = false
        case 2:
            ballAX = 0.35
            ballBX = 0.65
            ballAVX = 2.0
            ballBVX = -2.0
            collided = false
            law3Time = 0
        default:
            break
        }
    }

    private func updatePhysics(size: CGSize) {
        let dt = 1.0 / 60.0

        switch selectedLaw {
        case 0:
            if puckLaunched {
                if frictionOn {
                    puckVX *= 0.995  // Friction deceleration
                    if abs(puckVX) < 0.001 { puckVX = 0 }
                }
                puckX += puckVX * dt
                if puckX > 0.95 { puckX = 0.15; puckVX = 0; puckLaunched = false }
            }

        case 1:
            if law2Pushing {
                let accel = forceMagnitude / objectMass * 0.0001  // Scaled
                law2VX += accel
            } else {
                law2VX *= 0.998  // Mild friction when not pushing
            }
            law2X += law2VX * dt
            if law2X > 0.95 { law2X = 0.1; law2VX = 0; law2Pushing = false }

        case 2:
            law3Time += dt
            if !collided {
                ballAX += ballAVX * dt * 0.08
                ballBX += ballBVX * dt * 0.08

                if ballAX + 0.04 >= ballBX - 0.04 {
                    collided = true
                    let tempV = ballAVX
                    ballAVX = ballBVX * 0.95
                    ballBVX = tempV * 0.95
                }
            } else {
                ballAX += ballAVX * dt * 0.08
                ballBX += ballBVX * dt * 0.08
            }

        default:
            break
        }
    }

    // MARK: - Law 1: Inertia

    private func drawLaw1(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)
        let surfaceY = h * 0.6

        // Surface
        var surface = Path()
        surface.move(to: CGPoint(x: 0, y: surfaceY))
        surface.addLine(to: CGPoint(x: w, y: surfaceY))
        context.stroke(surface, with: .color(.white.opacity(0.3)), lineWidth: 1)

        // Surface label
        let surfLabel = Text(frictionOn ? "Rough Surface \u{2592}\u{2592}\u{2592}" : "Frictionless Surface (ice)")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.4))
        context.draw(surfLabel, at: CGPoint(x: w * 0.5, y: surfaceY + 15))

        // Puck
        let px = puckX * w
        let puckSize = 40.0
        let puckRect = CGRect(x: px - puckSize / 2, y: surfaceY - puckSize,
                               width: puckSize, height: puckSize)

        let puckColor = Color(red: 0.3, green: 0.5, blue: 0.9)
        context.fill(Path(roundedRect: puckRect, cornerRadius: 6),
                     with: .color(puckColor))

        // Velocity arrow
        if puckVX > 0.01 {
            let arrowLen = puckVX * 30
            var arrow = Path()
            arrow.move(to: CGPoint(x: px + puckSize / 2 + 5, y: surfaceY - puckSize / 2))
            arrow.addLine(to: CGPoint(x: px + puckSize / 2 + 5 + arrowLen, y: surfaceY - puckSize / 2))
            context.stroke(arrow, with: .color(.green), lineWidth: 2)

            let vLabel = Text(String(format: "v = %.2f m/s", puckVX * 100))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.green)
            context.draw(vLabel, at: CGPoint(x: px + puckSize / 2 + 5 + arrowLen / 2,
                                             y: surfaceY - puckSize / 2 - 12))
        }

        // Title and law statement
        let title = Text("First Law: An object in motion stays in motion unless acted upon by a force.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 25))

        // Mass label
        let mLabel = Text("m")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
        context.draw(mLabel, at: CGPoint(x: px, y: surfaceY - puckSize / 2))
    }

    // MARK: - Law 2: F = ma

    private func drawLaw2(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)
        let surfaceY = h * 0.6

        // Surface
        var surface = Path()
        surface.move(to: CGPoint(x: 0, y: surfaceY))
        surface.addLine(to: CGPoint(x: w, y: surfaceY))
        context.stroke(surface, with: .color(.white.opacity(0.3)), lineWidth: 1)

        // Object (box whose size reflects mass)
        let ox = law2X * w
        let boxSize = 25 + objectMass * 2.5
        let boxRect = CGRect(x: ox - boxSize / 2, y: surfaceY - boxSize,
                              width: boxSize, height: boxSize)

        let massColor = Color(red: 0.9, green: 0.5, blue: 0.2)
        context.fill(Path(roundedRect: boxRect, cornerRadius: 4), with: .color(massColor))

        let mLabel = Text(String(format: "%.1f kg", objectMass))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
        context.draw(mLabel, at: CGPoint(x: ox, y: surfaceY - boxSize / 2))

        // Force arrow (when pushing)
        if law2Pushing {
            let forceLen = forceMagnitude * 0.3
            var fArrow = Path()
            fArrow.move(to: CGPoint(x: ox - boxSize / 2 - forceLen, y: surfaceY - boxSize / 2))
            fArrow.addLine(to: CGPoint(x: ox - boxSize / 2 - 3, y: surfaceY - boxSize / 2))
            context.stroke(fArrow, with: .color(.red), lineWidth: 3)

            // Arrowhead
            var head = Path()
            head.move(to: CGPoint(x: ox - boxSize / 2 - 3, y: surfaceY - boxSize / 2))
            head.addLine(to: CGPoint(x: ox - boxSize / 2 - 10, y: surfaceY - boxSize / 2 - 5))
            head.move(to: CGPoint(x: ox - boxSize / 2 - 3, y: surfaceY - boxSize / 2))
            head.addLine(to: CGPoint(x: ox - boxSize / 2 - 10, y: surfaceY - boxSize / 2 + 5))
            context.stroke(head, with: .color(.red), lineWidth: 3)

            let fLabel = Text(String(format: "F = %d N", Int(forceMagnitude)))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red)
            context.draw(fLabel, at: CGPoint(x: ox - boxSize / 2 - forceLen / 2,
                                             y: surfaceY - boxSize / 2 - 15))
        }

        // Acceleration arrow
        if law2Pushing || law2VX > 0.01 {
            let accel = law2Pushing ? forceMagnitude / objectMass : 0
            let accelLen = accel * 0.3
            if accelLen > 2 {
                var aArrow = Path()
                aArrow.move(to: CGPoint(x: ox, y: surfaceY - boxSize - 15))
                aArrow.addLine(to: CGPoint(x: ox + accelLen, y: surfaceY - boxSize - 15))
                context.stroke(aArrow, with: .color(.cyan), lineWidth: 2)

                let aLabel = Text(String(format: "a = %.1f m/s\u{00B2}", accel))
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                context.draw(aLabel, at: CGPoint(x: ox + accelLen / 2, y: surfaceY - boxSize - 28))
            }

            // Velocity
            let vLabel = Text(String(format: "v = %.1f m/s", law2VX * 1000))
                .font(.system(size: 10))
                .foregroundColor(.green.opacity(0.7))
            context.draw(vLabel, at: CGPoint(x: ox, y: surfaceY + 25))
        }

        // Title
        let title = Text("Second Law: Force equals mass times acceleration (F = ma)")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 25))

        // Big formula
        let formula = Text("F = ma")
            .font(.system(size: 24, weight: .bold, design: .serif))
            .foregroundColor(.white.opacity(0.15))
        context.draw(formula, at: CGPoint(x: w * 0.8, y: h * 0.3))
    }

    // MARK: - Law 3: Action-Reaction

    private func drawLaw3(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)
        let midY = h * 0.5

        // Ball A (left, moving right)
        let ax = ballAX * w
        let bx = ballBX * w
        let ballR = 30.0

        // Ball A
        let aRect = CGRect(x: ax - ballR, y: midY - ballR, width: ballR * 2, height: ballR * 2)
        context.fill(Path(ellipseIn: aRect),
                     with: .radialGradient(
                        Gradient(colors: [.red, Color(red: 0.6, green: 0.1, blue: 0.1)]),
                        center: CGPoint(x: ax - 8, y: midY - 8),
                        startRadius: 0, endRadius: ballR))

        let aLabel = Text("A")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
        context.draw(aLabel, at: CGPoint(x: ax, y: midY))

        // Ball B
        let bRect = CGRect(x: bx - ballR, y: midY - ballR, width: ballR * 2, height: ballR * 2)
        context.fill(Path(ellipseIn: bRect),
                     with: .radialGradient(
                        Gradient(colors: [.blue, Color(red: 0.1, green: 0.1, blue: 0.6)]),
                        center: CGPoint(x: bx - 8, y: midY - 8),
                        startRadius: 0, endRadius: ballR))

        let bLabel = Text("B")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
        context.draw(bLabel, at: CGPoint(x: bx, y: midY))

        // Velocity arrows
        let vScale = 15.0
        if abs(ballAVX) > 0.01 {
            var vA = Path()
            vA.move(to: CGPoint(x: ax + (ballAVX > 0 ? ballR + 5 : -ballR - 5), y: midY))
            vA.addLine(to: CGPoint(x: ax + (ballAVX > 0 ? ballR + 5 : -ballR - 5) + ballAVX * vScale, y: midY))
            context.stroke(vA, with: .color(.green.opacity(0.7)), lineWidth: 2)
        }
        if abs(ballBVX) > 0.01 {
            var vB = Path()
            vB.move(to: CGPoint(x: bx + (ballBVX > 0 ? ballR + 5 : -ballR - 5), y: midY))
            vB.addLine(to: CGPoint(x: bx + (ballBVX > 0 ? ballR + 5 : -ballR - 5) + ballBVX * vScale, y: midY))
            context.stroke(vB, with: .color(.green.opacity(0.7)), lineWidth: 2)
        }

        // Force arrows during near-collision
        if showForces && !collided && abs(ax - bx) < ballR * 3 {
            let proximity = 1.0 - abs(ax - bx) / (ballR * 3)
            let forceLen = proximity * 40

            // Force on B from A (rightward)
            var fOnB = Path()
            fOnB.move(to: CGPoint(x: bx - ballR - 2, y: midY - 25))
            fOnB.addLine(to: CGPoint(x: bx - ballR - 2 + forceLen, y: midY - 25))
            context.stroke(fOnB, with: .color(.yellow), lineWidth: 2.5)
            let fBLabel = Text("F\u{2192}")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.yellow)
            context.draw(fBLabel, at: CGPoint(x: bx - ballR + forceLen / 2, y: midY - 38))

            // Force on A from B (leftward) - equal and opposite
            var fOnA = Path()
            fOnA.move(to: CGPoint(x: ax + ballR + 2, y: midY - 25))
            fOnA.addLine(to: CGPoint(x: ax + ballR + 2 - forceLen, y: midY - 25))
            context.stroke(fOnA, with: .color(.orange), lineWidth: 2.5)
            let fALabel = Text("\u{2190}F")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.orange)
            context.draw(fALabel, at: CGPoint(x: ax + ballR - forceLen / 2, y: midY - 38))
        }

        // Collision flash
        if collided && law3Time < 0.15 {
            let flashR = 20.0
            let midX = (ax + bx) / 2
            let flashRect = CGRect(x: midX - flashR, y: midY - flashR,
                                    width: flashR * 2, height: flashR * 2)
            context.fill(Path(ellipseIn: flashRect),
                         with: .color(.white.opacity(0.5)))
        }

        // Title
        let title = Text("Third Law: For every action, there is an equal and opposite reaction")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 25))

        let formula = Text("F\u{2081}\u{2082} = \u{2212}F\u{2082}\u{2081}")
            .font(.system(size: 20, weight: .bold, design: .serif))
            .foregroundColor(.white.opacity(0.15))
        context.draw(formula, at: CGPoint(x: w * 0.5, y: h - 30))
    }
}
