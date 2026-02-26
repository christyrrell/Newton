import SwiftUI
import Foundation

/// Particle fountain demonstrating gravity, acceleration, and drag.
/// Hundreds of particles launch upward and fall back under gravity,
/// creating a beautiful visual that shows F=ma in action.
struct ParticleGravityView: View {
    @State private var particles: [Particle] = []
    @State private var gravity: Double = 400
    @State private var emitRate: Double = 8
    @State private var initialSpeed: Double = 350
    @State private var spreadAngle: Double = 30
    @State private var showVectors: Bool = false
    @State private var colorMode: Int = 0  // 0=velocity, 1=height, 2=rainbow
    @State private var windForce: Double = 0
    @State private var frameCount: Int = 0

    private let maxParticles = 800

    struct Particle {
        var x: Double
        var y: Double
        var vx: Double
        var vy: Double
        var life: Double
        var maxLife: Double
        var size: Double
    }

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    updateParticles(size: size)
                    drawParticles(context: context, size: size)
                }
                .background(Color.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gravity: \(Int(gravity))")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $gravity, in: 0...800, step: 25)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch Speed: \(Int(initialSpeed))")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $initialSpeed, in: 100...600, step: 25)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Spread: \(Int(spreadAngle))\u{00B0}")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $spreadAngle, in: 5...90, step: 5)
                        .frame(width: 100)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wind: \(Int(windForce))")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $windForce, in: -200...200, step: 25)
                        .frame(width: 100)
                }

                Picker("Color", selection: $colorMode) {
                    Text("Velocity").tag(0)
                    Text("Height").tag(1)
                    Text("Rainbow").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Toggle("Vectors", isOn: $showVectors)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Spacer()
            }
            .padding()
        }
    }

    private func updateParticles(size: CGSize) {
        let dt = 1.0 / 60.0
        frameCount += 1
        let w = Double(size.width)
        let h = Double(size.height)

        // Emit new particles
        let emitCount = Int(emitRate)
        for _ in 0..<emitCount {
            if particles.count >= maxParticles { break }

            let angle = (.pi / 2) + Double.random(in: -spreadAngle...spreadAngle) * .pi / 180
            let speed = initialSpeed * Double.random(in: 0.8...1.2)

            let particle = Particle(
                x: w * 0.5 + Double.random(in: -5...5),
                y: h * 0.85,
                vx: Foundation.cos(angle) * speed,
                vy: -Foundation.sin(angle) * speed,
                life: 0,
                maxLife: Double.random(in: 3...6),
                size: Double.random(in: 2...5)
            )
            particles.append(particle)
        }

        // Update existing particles
        var i = 0
        while i < particles.count {
            // Apply gravity
            particles[i].vy += gravity * dt

            // Apply wind
            particles[i].vx += windForce * dt

            // Update position
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt
            particles[i].life += dt

            // Remove dead particles
            if particles[i].life > particles[i].maxLife ||
               particles[i].y > h + 20 ||
               particles[i].x < -20 || particles[i].x > w + 20 {
                particles.remove(at: i)
            } else {
                i += 1
            }
        }
    }

    private func drawParticles(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)

        // Ground line
        let groundY = h * 0.85
        var ground = Path()
        ground.move(to: CGPoint(x: 0, y: groundY))
        ground.addLine(to: CGPoint(x: w, y: groundY))
        context.stroke(ground, with: .color(.white.opacity(0.1)), lineWidth: 1)

        // Emitter glow
        let emitterX = w * 0.5
        for r in stride(from: 20.0, through: 5.0, by: -3.0) {
            let rect = CGRect(x: emitterX - r, y: groundY - r,
                               width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect),
                         with: .color(.orange.opacity(0.05)))
        }

        // Draw particles
        for particle in particles {
            let lifeRatio = particle.life / particle.maxLife
            let alpha = max(0, 1.0 - lifeRatio)
            let speed = Foundation.sqrt(particle.vx * particle.vx + particle.vy * particle.vy)

            let color: Color
            switch colorMode {
            case 0: // Velocity based
                let speedNorm = min(1, speed / 500)
                color = Color(
                    red: speedNorm,
                    green: 0.3 + (1 - speedNorm) * 0.5,
                    blue: 1 - speedNorm
                )
            case 1: // Height based
                let heightNorm = 1.0 - min(1, max(0, particle.y / h))
                color = Color(
                    red: 1.0 - heightNorm * 0.5,
                    green: heightNorm * 0.8,
                    blue: heightNorm
                )
            default: // Rainbow
                let hue = Foundation.fmod(particle.life * 0.3 + Double(particles.firstIndex(where: { $0.x == particle.x }) ?? 0) * 0.1, 1.0)
                color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
            }

            let rect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))

            // Velocity vectors
            if showVectors && frameCount % 3 == 0 {
                let scale = 0.02
                var vec = Path()
                vec.move(to: CGPoint(x: particle.x, y: particle.y))
                vec.addLine(to: CGPoint(x: particle.x + particle.vx * scale,
                                        y: particle.y + particle.vy * scale))
                context.stroke(vec, with: .color(.white.opacity(alpha * 0.2)), lineWidth: 0.5)
            }
        }

        // Stats
        let stats = Text("\(particles.count) particles  |  g = \(Int(gravity)) px/s\u{00B2}")
            .font(.system(size: 10).monospaced())
            .foregroundColor(.white.opacity(0.3))
        context.draw(stats, at: CGPoint(x: 80, y: h - 12))

        // Title
        let title = Text("Particle Gravity")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
        context.draw(title, at: CGPoint(x: w / 2, y: 20))

        let formula = Text("F = ma  \u{2014}  a = g + F\u{1D64}/m")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.25))
        context.draw(formula, at: CGPoint(x: w / 2, y: h - 12))
    }
}
