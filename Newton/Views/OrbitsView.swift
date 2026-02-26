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
    var trail: [(x: Double, y: Double)] = []
}

struct OrbitsView: View {
    @State private var bodies: [OrbitalBody] = []
    @State private var timeScale: Double = 1.0
    @State private var showTrails: Bool = true
    @State private var showVectors: Bool = false
    @State private var trailLength: Double = 400
    @State private var isPaused: Bool = false
    @State private var lastUpdate: Date = .now

    private let G: Double = 800

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    drawSystem(context: context, size: size)
                }
                .background(Color.black)
                .onAppear {
                    setupSolarSystem()
                }
                .onChange(of: timeline.date) { _, newDate in
                    if !isPaused {
                        let frameDt = min(newDate.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                        lastUpdate = newDate
                        updatePhysics(dt: frameDt)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

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
                    Slider(value: $trailLength, in: 50...1500)
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
                    if !isPaused { lastUpdate = .now }
                }
                .buttonStyle(.bordered)

                Spacer()

                Menu("Presets") {
                    Button("Solar System") { setupSolarSystem() }
                    Button("Binary Star") { setupBinaryStars() }
                    Button("Lagrange Points") { setupLagrange() }
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
            OrbitalBody(x: 80, y: 0, vx: 0, vy: 7.2, mass: 8, radius: 4,
                        color: Color(white: 0.7), name: "Mercury"),
            OrbitalBody(x: 135, y: 0, vx: 0, vy: 5.6, mass: 18, radius: 6,
                        color: Color(red: 0.9, green: 0.7, blue: 0.4), name: "Venus"),
            OrbitalBody(x: 195, y: 0, vx: 0, vy: 4.7, mass: 22, radius: 7,
                        color: Color(red: 0.3, green: 0.6, blue: 0.9), name: "Earth"),
            OrbitalBody(x: 260, y: 0, vx: 0, vy: 4.0, mass: 10, radius: 5,
                        color: Color(red: 0.9, green: 0.4, blue: 0.3), name: "Mars"),
            OrbitalBody(x: 370, y: 0, vx: 0, vy: 3.3, mass: 200, radius: 14,
                        color: Color(red: 0.8, green: 0.7, blue: 0.5), name: "Jupiter"),
        ]
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
    }

    private func setupLagrange() {
        // Sun-Earth-like system with objects at Lagrange-ish points
        bodies = [
            OrbitalBody(x: 0, y: 0, vx: 0, vy: 0, mass: 5000, radius: 20,
                        color: .yellow, name: "Sun"),
            OrbitalBody(x: 200, y: 0, vx: 0, vy: 4.6, mass: 25, radius: 7,
                        color: Color(red: 0.3, green: 0.6, blue: 0.9), name: "Earth"),
            // Trojan asteroid (leading L4)
            OrbitalBody(x: 200 * Foundation.cos(.pi / 3),
                        y: -200 * Foundation.sin(.pi / 3),
                        vx: 4.6 * Foundation.sin(.pi / 3),
                        vy: 4.6 * Foundation.cos(.pi / 3),
                        mass: 1, radius: 3,
                        color: Color(white: 0.6), name: "L4"),
            // Trailing L5
            OrbitalBody(x: 200 * Foundation.cos(.pi / 3),
                        y: 200 * Foundation.sin(.pi / 3),
                        vx: -4.6 * Foundation.sin(.pi / 3),
                        vy: 4.6 * Foundation.cos(.pi / 3),
                        mass: 1, radius: 3,
                        color: Color(white: 0.6), name: "L5"),
        ]
    }

    private func updatePhysics(dt: Double) {
        let steps = max(1, Int(timeScale * 4))
        let subDt = 0.016 / Double(steps)

        for _ in 0..<steps {
            var forces = Array(repeating: (fx: 0.0, fy: 0.0), count: bodies.count)

            for i in 0..<bodies.count {
                for j in (i + 1)..<bodies.count {
                    let dx = bodies[j].x - bodies[i].x
                    let dy = bodies[j].y - bodies[i].y
                    let distSq = max(dx * dx + dy * dy, 100)
                    let dist = Foundation.sqrt(distSq)
                    let force = G * bodies[i].mass * bodies[j].mass / distSq
                    let fx = force * dx / dist
                    let fy = force * dy / dist

                    forces[i].fx += fx
                    forces[i].fy += fy
                    forces[j].fx -= fx
                    forces[j].fy -= fy
                }
            }

            for i in 0..<bodies.count {
                let ax = forces[i].fx / bodies[i].mass
                let ay = forces[i].fy / bodies[i].mass
                bodies[i].vx += ax * subDt
                bodies[i].vy += ay * subDt
                bodies[i].x += bodies[i].vx * subDt
                bodies[i].y += bodies[i].vy * subDt

                bodies[i].trail.append((x: bodies[i].x, y: bodies[i].y))
                let maxTrail = Int(trailLength)
                if bodies[i].trail.count > maxTrail {
                    bodies[i].trail.removeFirst(bodies[i].trail.count - maxTrail)
                }
            }
        }
    }

    private func drawSystem(context: GraphicsContext, size: CGSize) {
        let cx = Double(size.width) / 2
        let cy = Double(size.height) / 2

        // Star field
        var rng = SeededRNG(seed: 42)
        for _ in 0..<120 {
            let sx = Double.random(in: 0...Double(size.width), using: &rng)
            let sy = Double.random(in: 0...Double(size.height), using: &rng)
            let brightness = Double.random(in: 0.05...0.35, using: &rng)
            let starSize = Double.random(in: 0.5...1.5, using: &rng)
            context.fill(Path(ellipseIn: CGRect(x: sx, y: sy, width: starSize, height: starSize)),
                         with: .color(.white.opacity(brightness)))
        }

        // Trails
        if showTrails {
            for body in bodies {
                guard body.trail.count > 2 else { continue }
                let step = max(1, body.trail.count / 500) // Limit number of segments drawn
                var i = step
                while i < body.trail.count {
                    let opacity = Double(i) / Double(body.trail.count) * 0.5
                    let prev = body.trail[i - step]
                    let cur = body.trail[i]
                    var segment = Path()
                    segment.move(to: CGPoint(x: cx + prev.x, y: cy + prev.y))
                    segment.addLine(to: CGPoint(x: cx + cur.x, y: cy + cur.y))
                    context.stroke(segment, with: .color(body.color.opacity(opacity)),
                                   lineWidth: 1)
                    i += step
                }
            }
        }

        // Bodies
        for body in bodies {
            let bx = cx + body.x
            let by = cy + body.y
            let r = body.radius

            // Glow for massive bodies (stars)
            if body.mass > 500 {
                for glowR in stride(from: r * 4, through: r, by: -3) {
                    let opacity = 0.04 * (1 - (glowR - r) / (r * 3))
                    context.fill(Path(ellipseIn: CGRect(x: bx - glowR, y: by - glowR,
                                                         width: glowR * 2, height: glowR * 2)),
                                 with: .color(body.color.opacity(opacity)))
                }
            }

            // Body
            let gradient = Gradient(colors: [body.color, body.color.opacity(0.6)])
            context.fill(
                Path(ellipseIn: CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)),
                with: .radialGradient(gradient,
                                      center: CGPoint(x: bx - r * 0.25, y: by - r * 0.25),
                                      startRadius: 0, endRadius: r)
            )

            // Label
            let label = Text(body.name)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
            context.draw(label, at: CGPoint(x: bx, y: by - r - 8))

            // Velocity vectors
            if showVectors {
                let scale = 5.0
                var arrow = Path()
                arrow.move(to: CGPoint(x: bx, y: by))
                arrow.addLine(to: CGPoint(x: bx + body.vx * scale, y: by + body.vy * scale))
                context.stroke(arrow, with: .color(.green.opacity(0.5)), lineWidth: 1)
            }
        }

        // HUD
        let title = Text("Universal Gravitation")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
        context.draw(title, at: CGPoint(x: cx, y: 20))

        let formula = Text("F = G \u{00B7} m\u{2081}m\u{2082} / r\u{00B2}")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.25))
        context.draw(formula, at: CGPoint(x: cx, y: Double(size.height) - 12))

        // Body count
        let count = Text("\(bodies.count) bodies")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.3))
        context.draw(count, at: CGPoint(x: 40, y: 15))
    }
}

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
