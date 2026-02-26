import SwiftUI
import Foundation

struct CalculusView: View {
    @State private var selectedFunction = 0
    @State private var showDerivative = true
    @State private var showIntegral = false
    @State private var riemannN: Double = 10
    @State private var tangentX: Double = 0.5
    @State private var animateRiemann = false
    @State private var showTangent = true

    private let functions: [(name: String, f: (Double) -> Double, df: (Double) -> Double, label: String, derivLabel: String)] = [
        ("x\u{00B2}", { x in x * x }, { x in 2 * x }, "f(x) = x\u{00B2}", "f'(x) = 2x"),
        ("sin(x)", { x in sin(x) }, { x in cos(x) }, "f(x) = sin(x)", "f'(x) = cos(x)"),
        ("x\u{00B3} - x", { x in x * x * x - x }, { x in 3 * x * x - 1 }, "f(x) = x\u{00B3} - x", "f'(x) = 3x\u{00B2} - 1"),
        ("e^(-x\u{00B2})", { x in exp(-x * x) }, { x in -2 * x * exp(-x * x) }, "f(x) = e^(-x\u{00B2})", "f'(x) = -2xe^(-x\u{00B2})"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    drawGraph(context: context, size: size, date: timeline.date)
                }
                .background(Color(white: 0.05))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
            HStack(spacing: 20) {
                Picker("Function", selection: $selectedFunction) {
                    ForEach(0..<functions.count, id: \.self) { i in
                        Text(functions[i].name).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tangent at x = \(String(format: "%.2f", tangentX * 4 - 2))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $tangentX, in: 0...1)
                        .frame(width: 150)
                }

                Toggle("Tangent", isOn: $showTangent)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Derivative", isOn: $showDerivative)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Toggle("Integral", isOn: $showIntegral)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                if showIntegral {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rectangles: \(Int(riemannN))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $riemannN, in: 2...100, step: 1)
                            .frame(width: 120)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    private func drawGraph(context: GraphicsContext, size: CGSize, date: Date) {
        let w = size.width
        let h = size.height
        let f = functions[selectedFunction]

        // Coordinate system mapping
        let xMin: Double = -3
        let xMax: Double = 3
        let yMin: Double = -2
        let yMax: Double = 3

        func toScreen(_ x: Double, _ y: Double) -> CGPoint {
            let sx = (x - xMin) / (xMax - xMin) * Double(w)
            let sy = (1 - (y - yMin) / (yMax - yMin)) * Double(h)
            return CGPoint(x: sx, y: sy)
        }

        func toGraphX(_ screenX: Double) -> Double {
            return xMin + screenX / Double(w) * (xMax - xMin)
        }

        // Grid
        for x in stride(from: ceil(xMin), through: floor(xMax), by: 1) {
            let p1 = toScreen(x, yMin)
            let p2 = toScreen(x, yMax)
            var line = Path()
            line.move(to: p1)
            line.addLine(to: p2)
            context.stroke(line, with: .color(.white.opacity(x == 0 ? 0.3 : 0.08)), lineWidth: x == 0 ? 1 : 0.5)

            if x != 0 {
                let label = Text(String(format: "%.0f", x))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
                context.draw(label, at: CGPoint(x: toScreen(x, 0).x, y: toScreen(0, 0).y + 12))
            }
        }

        for y in stride(from: ceil(yMin), through: floor(yMax), by: 1) {
            let p1 = toScreen(xMin, y)
            let p2 = toScreen(xMax, y)
            var line = Path()
            line.move(to: p1)
            line.addLine(to: p2)
            context.stroke(line, with: .color(.white.opacity(y == 0 ? 0.3 : 0.08)), lineWidth: y == 0 ? 1 : 0.5)

            if y != 0 {
                let label = Text(String(format: "%.0f", y))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
                context.draw(label, at: CGPoint(x: toScreen(0, y).x - 12, y: toScreen(0, y).y))
            }
        }

        // Riemann sum (integral visualization)
        if showIntegral {
            let n = Int(riemannN)
            let integralStart: Double = -2
            let integralEnd: Double = 2
            let dx = (integralEnd - integralStart) / Double(n)

            for i in 0..<n {
                let x = integralStart + Double(i) * dx
                let y = f.f(x + dx / 2)  // Midpoint rule

                let topLeft = toScreen(x, max(0, y))
                let bottomRight = toScreen(x + dx, min(0, y))
                let rect = CGRect(
                    x: min(topLeft.x, bottomRight.x),
                    y: min(topLeft.y, bottomRight.y),
                    width: abs(bottomRight.x - topLeft.x),
                    height: abs(bottomRight.y - topLeft.y)
                )

                let fillColor: Color = y >= 0
                    ? Color.blue.opacity(0.2)
                    : Color.red.opacity(0.2)
                context.fill(Path(rect), with: .color(fillColor))

                let borderColor: Color = y >= 0
                    ? Color.blue.opacity(0.4)
                    : Color.red.opacity(0.4)
                context.stroke(Path(rect), with: .color(borderColor), lineWidth: 0.5)
            }

            // Integral value
            let integralValue = numericalIntegral(f: f.f, from: integralStart, to: integralEnd, n: 1000)
            let integralLabel = Text("\u{222B} f(x)dx \u{2248} \(String(format: "%.3f", integralValue))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.cyan.opacity(0.8))
            context.draw(integralLabel, at: CGPoint(x: w - 100, y: 40))
        }

        // Main function curve
        var functionPath = Path()
        var started = false
        for screenX in stride(from: 0, through: Double(w), by: 1) {
            let x = toGraphX(screenX)
            let y = f.f(x)
            let point = toScreen(x, y)
            if point.y > -50 && point.y < Double(h) + 50 {
                if !started {
                    functionPath.move(to: point)
                    started = true
                } else {
                    functionPath.addLine(to: point)
                }
            } else {
                started = false
            }
        }
        context.stroke(functionPath, with: .color(.white), lineWidth: 2)

        // Derivative curve
        if showDerivative {
            var derivPath = Path()
            started = false
            for screenX in stride(from: 0, through: Double(w), by: 1) {
                let x = toGraphX(screenX)
                let y = f.df(x)
                let point = toScreen(x, y)
                if point.y > -50 && point.y < Double(h) + 50 {
                    if !started {
                        derivPath.move(to: point)
                        started = true
                    } else {
                        derivPath.addLine(to: point)
                    }
                } else {
                    started = false
                }
            }
            context.stroke(derivPath, with: .color(.orange.opacity(0.7)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
        }

        // Tangent line
        if showTangent {
            let tx = tangentX * (xMax - xMin) + xMin
            let ty = f.f(tx)
            let slope = f.df(tx)

            // Draw tangent line
            let extent: Double = 1.5
            let tStart = toScreen(tx - extent, ty - slope * extent)
            let tEnd = toScreen(tx + extent, ty + slope * extent)
            var tangentPath = Path()
            tangentPath.move(to: tStart)
            tangentPath.addLine(to: tEnd)
            context.stroke(tangentPath, with: .color(.green.opacity(0.8)), lineWidth: 1.5)

            // Draw point
            let pointPos = toScreen(tx, ty)
            let pointRect = CGRect(x: pointPos.x - 4, y: pointPos.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: pointRect), with: .color(.green))

            // Slope label
            let slopeLabel = Text("slope = \(String(format: "%.2f", slope))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.green.opacity(0.9))
            context.draw(slopeLabel, at: CGPoint(x: pointPos.x + 50, y: pointPos.y - 15))
        }

        // Legend
        let funcLabel = Text(f.label)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
        context.draw(funcLabel, at: CGPoint(x: 80, y: 20))

        if showDerivative {
            let derivLabel = Text(f.derivLabel)
                .font(.system(size: 12))
                .foregroundColor(.orange.opacity(0.8))
            context.draw(derivLabel, at: CGPoint(x: 80, y: 38))
        }

        // Title
        let title = Text("The Method of Fluxions")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w / 2, y: h - 15))
    }

    private func numericalIntegral(f: (Double) -> Double, from a: Double, to b: Double, n: Int) -> Double {
        let dx = (b - a) / Double(n)
        var sum = 0.0
        for i in 0..<n {
            let x = a + (Double(i) + 0.5) * dx
            sum += f(x) * dx
        }
        return sum
    }
}
