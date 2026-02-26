import SwiftUI
import Foundation

struct OrbitalBody {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var mass: Double
    var radius: Double
    var color: Color
    var name: String
    var trail: [CGPoint] = []
}

struct OrbitsView: View {
    @State private var bodies: [OrbitalBody] = []
    @State private var timeScale: Double = 1.0
    @State private var showTrails: Bool = true
    @State private var showVectors: Bool = false
    @State private var trailLength: Double = 300
    @State private var isPaused: Bool = false
    @State private var elapsedTime: Double = 0

    private let G: Double = 800  // Gravitational constant (scaled for visual effect)
    private let dt: Double = 0.016

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    if !isPaused {
                        updatePhysics(size: size)
                    }
                    drawSystem(context: context, size: size)
                }
                .background(Color.black)
                .onAppear {
                    setupSolarSystem()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed: \(String(format: "%.1f", timeScale))x")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $timeScale, in: 0.1...5.0)
                        .frame(width: 150)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Trail Length")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $trailLength, in: 50...1000)
                        .frame(width: 150)
                }

                Toggle("Trails", isOn: $showTrails)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Velocity", isOn: $showVectors)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
                }
                .buttonStyle(.bordered)

                Spacer()

                Menu("Presets") {
                    Button("Solar System") { setupSolarSystem() }
                    Button("Binary Star") { setupBinaryStars() }
                    Button("Figure Eight") { setupFigureEight() }
                }
                .menuStyle(.borderedButton)

                Button("Reset") {
                    setupSolarSystem()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private func setupSolarSystem() {
        bodies = [
            OrbitalBody(x: 0, y: 0, vx: 0, vy: 0, mass: 5000, radius: 22,
                        color: .yellow, name: "Sun"),
            OrbitalBody(x: 100, y: 0, vx: 0, vy: 6.5, mass: 10, radius: 5,
                        color: Color(red: 0.7, green: 0.7, blue: 0.7), name: "Mercury"),
            OrbitalBody(x: 160, y: 0, vx: 0, vy: 5.2, mass: 20, radius: 7,
                        color: Color(red: 0.9, green: 0.7, blue: 0.4), name: "Venus"),
            OrbitalBody(x: 220, y: 0, vx: 0, vy: 4.5, mass: 25, radius: 8,
                        color: Color(red: 0.3, green: 0.6, blue: 0.9), name: "Earth"),
            OrbitalBody(x: 300, y: 0, vx: 0, vy: 3.8, mass: 12, radius: 6,
                        color: Color(red: 0.9, green: 0.4, blue: 0.3), name: "Mars"),
        ]
        elapsedTime = 0
    }

    private func setupBinaryStars() {
        bodies = [
            OrbitalBody(x: -80, y: 0, vx: 0, vy: -2.5, mass: 2000, radius: 16,
                        color: .orange, name: "Star A"),
            OrbitalBody(x: 80, y: 0, vx: 0, vy: 2.5, mass: 2000, radius: 16,
                        color: Color(red: 0.6, green: 0.8, blue: 1.0), name: "Star B"),
            OrbitalBody(x: 250, y: 0, vx: 0, vy: 4.2, mass: 5, radius: 4,
                        color: .green, name: "Planet"),
        ]
        elapsedTime = 0
    }

    private func setupFigureEight() {
        // Stable figure-eight three-body solution
        let v = 3.5
        bodies = [
            OrbitalBody(x: -100, y: 0, vx: 0, vy: -v, mass: 1000, radius: 10,
                        color: .red, name: "A"),
            OrbitalBody(x: 100, y: 0, vx: 0, vy: v, mass: 1000, radius: 10,
                        color: .green, name: "B"),
            OrbitalBody(x: 0, y: 0, vx: v * 0.8, vy: 0, mass: 1000, radius: 10,
                        color: .cyan, name: "C"),
        ]
        elapsedTime = 0
    }

    private func updatePhysics(size: CGSize) {
        let steps = max(1, Int(timeScale * 3))

        for _ in 0..<steps {
            // Calculate forces
            var forces = Array(repeating: (fx: 0.0, fy: 0.0), count: bodies.count)

            for i in 0..<bodies.count {
                for j in (i + 1)..<bodies.count {
                    let dx = bodies[j].x - bodies[i].x
                    let dy = bodies[j].y - bodies[i].y
                    let distSq = max(dx * dx + dy * dy, 100)  // Softening
                    let dist = sqrt(distSq)
                    let force = G * bodies[i].mass * bodies[j].mass / distSq
                    let fx = force * dx / dist
                    let fy = force * dy / dist

                    forces[i].fx += fx
                    forces[i].fy += fy
                    forces[j].fx -= fx
                    forces[j].fy -= fy
                }
            }

            // Update velocities and positions (Velocity Verlet)
            for i in 0..<bodies.count {
                let ax = forces[i].fx / bodies[i].mass
                let ay = forces[i].fy / bodies[i].mass

                bodies[i].vx += ax * dt
                bodies[i].vy += ay * dt
                bodies[i].x += bodies[i].vx * dt
                bodies[i].y += bodies[i].vy * dt

                // Record trail
                let cx = size.width / 2 + bodies[i].x
                let cy = size.height / 2 + bodies[i].y
                bodies[i].trail.append(CGPoint(x: cx, y: cy))

                let maxTrail = Int(trailLength)
                if bodies[i].trail.count > maxTrail {
                    bodies[i].trail.removeFirst(bodies[i].trail.count - maxTrail)
                }
            }

            elapsedTime += dt
        }
    }

    private func drawSystem(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2

        // Draw star field background (static dots)
        let starSeed: UInt64 = 42
        var rng = SeededRNG(seed: starSeed)
        for _ in 0..<100 {
            let sx = Double.random(in: 0...size.width, using: &rng)
            let sy = Double.random(in: 0...size.height, using: &rng)
            let brightness = Double.random(in: 0.1...0.4, using: &rng)
            let starSize = Double.random(in: 0.5...1.5, using: &rng)
            let rect = CGRect(x: sx, y: sy, width: starSize, height: starSize)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(brightness)))
        }

        // Draw trails
        if showTrails {
            for body in bodies {
                guard body.trail.count > 1 else { continue }
                for i in 1..<body.trail.count {
                    let opacity = Double(i) / Double(body.trail.count) * 0.6
                    var segment = Path()
                    segment.move(to: body.trail[i - 1])
                    segment.addLine(to: body.trail[i])
                    context.stroke(segment, with: .color(body.color.opacity(opacity)), lineWidth: 1)
                }
            }
        }

        // Draw bodies
        for body in bodies {
            let bx = cx + body.x
            let by = cy + body.y
            let r = body.radius

            // Glow effect for stars (large mass)
            if body.mass > 500 {
                for glowR in stride(from: r * 3, through: r, by: -2) {
                    let opacity = 0.05 * (1 - (glowR - r) / (r * 2))
                    let rect = CGRect(x: bx - glowR, y: by - glowR,
                                      width: glowR * 2, height: glowR * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(body.color.opacity(opacity)))
                }
            }

            // Body
            let rect = CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)
            let gradient = Gradient(colors: [body.color, body.color.opacity(0.7)])
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(gradient, center: CGPoint(x: bx - r * 0.2, y: by - r * 0.2),
                                      startRadius: 0, endRadius: r)
            )

            // Label
            let label = Text(body.name)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
            context.draw(label, at: CGPoint(x: bx, y: by - r - 8))

            // Velocity vector
            if showVectors {
                let scale = 5.0
                var arrow = Path()
                arrow.move(to: CGPoint(x: bx, y: by))
                arrow.addLine(to: CGPoint(x: bx + body.vx * scale, y: by + body.vy * scale))
                context.stroke(arrow, with: .color(.white.opacity(0.5)), lineWidth: 1)
            }
        }

        // HUD
        let title = Text("Universal Gravitation")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: cx, y: 20))

        let formula = Text("F = G \u{00B7} m\u{2081}m\u{2082} / r\u{00B2}")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.3))
        context.draw(formula, at: CGPoint(x: cx, y: size.height - 12))
    }
}

/// Deterministic random number generator for consistent star fields
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
