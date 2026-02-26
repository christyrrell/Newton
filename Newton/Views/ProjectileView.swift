import SwiftUI
import Foundation

struct Projectile {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var trail: [CGPoint]
    var color: Color
    var active: Bool
    var time: Double
}

struct ProjectileView: View {
    @State private var launchAngle: Double = 45
    @State private var launchSpeed: Double = 200
    @State private var gravity: Double = 9.81
    @State private var showAirResistance: Bool = false
    @State private var projectiles: [Projectile] = []
    @State private var showGrid: Bool = true
    @State private var showOptimalAngle: Bool = false

    private let groundY: Double = 0.85  // Ground level as fraction of height
    private let launchX: Double = 0.08  // Launch position as fraction of width

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    Canvas { context, size in
                        drawScene(context: context, size: size)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.05, blue: 0.15),
                                Color(red: 0.1, green: 0.15, blue: 0.25),
                                Color(red: 0.15, green: 0.25, blue: 0.15),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onChange(of: timeline.date) { _, _ in
                        updateProjectiles(size: geo.size)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Angle: \(Int(launchAngle))\u{00B0}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $launchAngle, in: 5...85, step: 1)
                        .frame(width: 150)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed: \(Int(launchSpeed)) m/s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $launchSpeed, in: 50...400, step: 10)
                        .frame(width: 150)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gravity: \(String(format: "%.1f", gravity)) m/s\u{00B2}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $gravity, in: 1...20, step: 0.5)
                        .frame(width: 150)
                }

                Toggle("Air Resistance", isOn: $showAirResistance)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Optimal 45\u{00B0}", isOn: $showOptimalAngle)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Button("Launch") {
                    launch()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])

                Spacer()

                Button("Clear") {
                    projectiles.removeAll()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private func launch() {
        let angleRad = launchAngle * .pi / 180
        let vx = launchSpeed * cos(angleRad)
        let vy = -launchSpeed * sin(angleRad)  // Negative because screen Y is inverted

        let hue = Double.random(in: 0...1)
        let color = Color(hue: hue, saturation: 0.7, brightness: 0.9)

        let proj = Projectile(
            x: 0, y: 0, vx: vx, vy: vy,
            trail: [], color: color, active: true, time: 0
        )
        projectiles.append(proj)

        // Also launch with air resistance for comparison
        if showAirResistance {
            let projAir = Projectile(
                x: 0, y: 0, vx: vx, vy: vy,
                trail: [], color: color.opacity(0.5), active: true, time: 0
            )
            projectiles.append(projAir)
        }
    }

    private func updateProjectiles(size: CGSize) {
        let dt = 1.0 / 60.0
        let gndY = size.height * groundY
        let startX = size.width * launchX

        for i in 0..<projectiles.count {
            guard projectiles[i].active else { continue }

            let screenX = startX + projectiles[i].x * 0.8
            let screenY = gndY + projectiles[i].y * 0.8

            projectiles[i].trail.append(CGPoint(x: screenX, y: screenY))

            // Apply gravity
            projectiles[i].vy += gravity * 60 * dt  // Scale gravity

            // Apply air resistance for even-indexed projectiles when enabled
            if showAirResistance && i % 2 == 1 {
                let dragCoeff = 0.002
                let speed = sqrt(projectiles[i].vx * projectiles[i].vx + projectiles[i].vy * projectiles[i].vy)
                if speed > 0 {
                    projectiles[i].vx -= dragCoeff * projectiles[i].vx * speed * dt * 60
                    projectiles[i].vy -= dragCoeff * projectiles[i].vy * speed * dt * 60
                }
            }

            projectiles[i].x += projectiles[i].vx * dt
            projectiles[i].y += projectiles[i].vy * dt
            projectiles[i].time += dt

            // Check if hit ground
            if screenY > gndY {
                projectiles[i].active = false
            }

            // Remove if off screen
            if screenX > size.width + 50 {
                projectiles[i].active = false
            }
        }
    }

    private func drawScene(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let gndY = h * groundY
        let startX = w * launchX

        // Ground
        var groundPath = Path()
        groundPath.move(to: CGPoint(x: 0, y: gndY))
        groundPath.addLine(to: CGPoint(x: w, y: gndY))
        context.stroke(groundPath, with: .color(.white.opacity(0.3)), lineWidth: 1)

        // Ground fill
        let groundRect = CGRect(x: 0, y: gndY, width: w, height: h - gndY)
        context.fill(Path(groundRect), with: .color(Color(red: 0.1, green: 0.15, blue: 0.1).opacity(0.5)))

        // Distance markers
        let pixelsPerMeter = 0.8
        for dist in stride(from: 100.0, through: 1000.0, by: 100.0) {
            let markerX = startX + dist * pixelsPerMeter
            guard markerX < w else { break }

            var tick = Path()
            tick.move(to: CGPoint(x: markerX, y: gndY - 3))
            tick.addLine(to: CGPoint(x: markerX, y: gndY + 3))
            context.stroke(tick, with: .color(.white.opacity(0.2)), lineWidth: 1)

            let label = Text("\(Int(dist))m")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.3))
            context.draw(label, at: CGPoint(x: markerX, y: gndY + 12))
        }

        // Height markers
        for height in stride(from: 100.0, through: 500.0, by: 100.0) {
            let markerY = gndY - height * pixelsPerMeter
            guard markerY > 0 else { break }

            var tick = Path()
            tick.move(to: CGPoint(x: startX - 3, y: markerY))
            tick.addLine(to: CGPoint(x: startX + 3, y: markerY))
            context.stroke(tick, with: .color(.white.opacity(0.2)), lineWidth: 1)

            let label = Text("\(Int(height))m")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.3))
            context.draw(label, at: CGPoint(x: startX - 18, y: markerY))
        }

        // Optimal 45 degree trajectory (theoretical)
        if showOptimalAngle {
            let optAngle = 45.0 * .pi / 180
            let v = launchSpeed
            var optPath = Path()
            var started = false

            for t in stride(from: 0.0, through: 10.0, by: 0.02) {
                let ox = v * cos(optAngle) * t
                let oy = v * sin(optAngle) * t - 0.5 * gravity * t * t

                guard oy >= 0 else { break }

                let sx = startX + ox * pixelsPerMeter
                let sy = gndY - oy * pixelsPerMeter

                if !started {
                    optPath.move(to: CGPoint(x: sx, y: sy))
                    started = true
                } else {
                    optPath.addLine(to: CGPoint(x: sx, y: sy))
                }
            }

            context.stroke(optPath, with: .color(.yellow.opacity(0.3)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            let optLabel = Text("Optimal (45\u{00B0})")
                .font(.system(size: 9))
                .foregroundColor(.yellow.opacity(0.4))
            context.draw(optLabel, at: CGPoint(x: w * 0.5, y: gndY - 10))
        }

        // Draw launch indicator
        let angleRad = launchAngle * .pi / 180
        let indicatorLen: CGFloat = 40
        var indicator = Path()
        indicator.move(to: CGPoint(x: startX, y: gndY))
        indicator.addLine(to: CGPoint(x: startX + indicatorLen * CGFloat(Foundation.cos(angleRad)),
                                       y: gndY - indicatorLen * CGFloat(Foundation.sin(angleRad))))
        context.stroke(indicator, with: .color(.white.opacity(0.5)), lineWidth: 2)

        // Launch point
        let launchRect = CGRect(x: startX - 3, y: gndY - 3, width: 6, height: 6)
        context.fill(Path(ellipseIn: launchRect), with: .color(.white))

        // Angle arc
        var arcPath = Path()
        arcPath.addArc(center: CGPoint(x: startX, y: gndY),
                       radius: 20,
                       startAngle: .degrees(0),
                       endAngle: .degrees(-launchAngle),
                       clockwise: true)
        context.stroke(arcPath, with: .color(.white.opacity(0.3)), lineWidth: 1)

        let angleLabel = Text("\(Int(launchAngle))\u{00B0}")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.5))
        context.draw(angleLabel, at: CGPoint(x: startX + 30, y: gndY - 10))

        // Draw projectile trails and current positions
        for proj in projectiles {
            // Trail
            if proj.trail.count > 1 {
                for i in 1..<proj.trail.count {
                    let opacity = Double(i) / Double(proj.trail.count)
                    var segment = Path()
                    segment.move(to: proj.trail[i - 1])
                    segment.addLine(to: proj.trail[i])
                    context.stroke(segment, with: .color(proj.color.opacity(opacity * 0.8)), lineWidth: 2)
                }
            }

            // Current position (if active)
            if proj.active, let lastPos = proj.trail.last {
                let ballRect = CGRect(x: lastPos.x - 4, y: lastPos.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: ballRect), with: .color(proj.color))

                // Glow
                let glowRect = CGRect(x: lastPos.x - 8, y: lastPos.y - 8, width: 16, height: 16)
                context.fill(Path(ellipseIn: glowRect), with: .color(proj.color.opacity(0.3)))
            }

            // Landing marker
            if !proj.active, let lastPos = proj.trail.last {
                var cross = Path()
                cross.move(to: CGPoint(x: lastPos.x - 4, y: gndY - 4))
                cross.addLine(to: CGPoint(x: lastPos.x + 4, y: gndY + 4))
                cross.move(to: CGPoint(x: lastPos.x + 4, y: gndY - 4))
                cross.addLine(to: CGPoint(x: lastPos.x - 4, y: gndY + 4))
                context.stroke(cross, with: .color(proj.color.opacity(0.6)), lineWidth: 1)
            }
        }

        // Theoretical range display
        let theoreticalRange = launchSpeed * launchSpeed * sin(2 * launchAngle * .pi / 180) / gravity
        let maxHeight = (launchSpeed * sin(launchAngle * .pi / 180)) * (launchSpeed * sin(launchAngle * .pi / 180)) / (2 * gravity)
        let flightTime = 2 * launchSpeed * sin(launchAngle * .pi / 180) / gravity

        let stats = Text("Range: \(Int(theoreticalRange))m | Max Height: \(Int(maxHeight))m | Time: \(String(format: "%.1f", flightTime))s")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.5))
        context.draw(stats, at: CGPoint(x: w / 2, y: 20))

        // Title
        let title = Text("Projectile Motion  \u{2014}  F = ma")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w / 2, y: h - 15))

        // Formula
        let formula = Text("R = v\u{2080}\u{00B2} sin(2\u{03B8}) / g")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.3))
        context.draw(formula, at: CGPoint(x: w / 2, y: h - 30))
    }
}
