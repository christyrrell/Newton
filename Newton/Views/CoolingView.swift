import SwiftUI
import Foundation

/// Newton's Law of Cooling: dT/dt = -k(T - T_env)
/// Solution: T(t) = T_env + (T_0 - T_env) * e^(-kt)
struct CoolingView: View {
    @State private var initialTemp: Double = 95  // degrees C
    @State private var envTemp: Double = 22       // room temperature
    @State private var coolingRate: Double = 0.05 // k constant
    @State private var time: Double = 0
    @State private var isRunning: Bool = false
    @State private var showExponential: Bool = true
    @State private var showLinearComparison: Bool = false
    @State private var dataPoints: [(time: Double, temp: Double)] = []
    @State private var lastUpdate: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    drawScene(context: context, size: size)
                }
                .background(Color(white: 0.04))
                .onChange(of: timeline.date) { _, newDate in
                    if isRunning {
                        let dt = min(newDate.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                        lastUpdate = newDate
                        time += dt * 3
                        recordDataPoint()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            HStack(spacing: 20) {
                Button(isRunning ? "Pause" : (time > 0 ? "Resume" : "Start Cooling")) {
                    isRunning.toggle()
                    if isRunning { lastUpdate = .now }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    time = 0
                    isRunning = false
                    dataPoints = []
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Initial: \(Int(initialTemp))\u{00B0}C")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $initialTemp, in: 40...100, step: 5)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Room: \(Int(envTemp))\u{00B0}C")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $envTemp, in: 0...35, step: 1)
                        .frame(width: 100)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("k = \(String(format: "%.3f", coolingRate))")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $coolingRate, in: 0.01...0.15, step: 0.005)
                        .frame(width: 100)
                }

                Toggle("Exponential", isOn: $showExponential)
                    .toggleStyle(.checkbox).font(.caption)

                Toggle("Linear (comparison)", isOn: $showLinearComparison)
                    .toggleStyle(.checkbox).font(.caption)

                Spacer()
            }
            .padding()
        }
    }

    private func recordDataPoint() {
        let interval = 0.5
        if dataPoints.isEmpty || time - (dataPoints.last?.time ?? 0) >= interval {
            let temp = currentTemperature(at: time)
            dataPoints.append((time: time, temp: temp))
        }
    }

    private func currentTemperature(at t: Double) -> Double {
        return envTemp + (initialTemp - envTemp) * Foundation.exp(-coolingRate * t)
    }

    private func drawScene(context: GraphicsContext, size: CGSize) {
        let w = Double(size.width)
        let h = Double(size.height)

        // Layout: thermometer visualization on left, graph on right
        let graphLeft = w * 0.08
        let graphRight = w * 0.92
        let graphTop = h * 0.1
        let graphBottom = h * 0.82

        // Temperature range
        let tempMin = max(0, envTemp - 5)
        let tempMax = initialTemp + 5
        let timeMax = max(60, time + 10)

        // Map functions
        func toScreenX(_ t: Double) -> Double {
            return graphLeft + (t / timeMax) * (graphRight - graphLeft)
        }
        func toScreenY(_ temp: Double) -> Double {
            return graphBottom - ((temp - tempMin) / (tempMax - tempMin)) * (graphBottom - graphTop)
        }

        // Grid
        // Temperature grid lines
        for temp in stride(from: Foundation.ceil(tempMin / 10) * 10, through: tempMax, by: 10) {
            let y = toScreenY(temp)
            var gridLine = Path()
            gridLine.move(to: CGPoint(x: graphLeft, y: y))
            gridLine.addLine(to: CGPoint(x: graphRight, y: y))
            context.stroke(gridLine, with: .color(.white.opacity(0.06)), lineWidth: 0.5)

            let label = Text("\(Int(temp))\u{00B0}")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.3))
            context.draw(label, at: CGPoint(x: graphLeft - 16, y: y))
        }

        // Time grid lines
        for t in stride(from: 10.0, through: timeMax, by: 10) {
            let x = toScreenX(t)
            var gridLine = Path()
            gridLine.move(to: CGPoint(x: x, y: graphTop))
            gridLine.addLine(to: CGPoint(x: x, y: graphBottom))
            context.stroke(gridLine, with: .color(.white.opacity(0.06)), lineWidth: 0.5)

            let label = Text("\(Int(t))s")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.3))
            context.draw(label, at: CGPoint(x: x, y: graphBottom + 12))
        }

        // Axes
        var xAxis = Path()
        xAxis.move(to: CGPoint(x: graphLeft, y: graphBottom))
        xAxis.addLine(to: CGPoint(x: graphRight, y: graphBottom))
        context.stroke(xAxis, with: .color(.white.opacity(0.3)), lineWidth: 1)

        var yAxis = Path()
        yAxis.move(to: CGPoint(x: graphLeft, y: graphTop))
        yAxis.addLine(to: CGPoint(x: graphLeft, y: graphBottom))
        context.stroke(yAxis, with: .color(.white.opacity(0.3)), lineWidth: 1)

        // Environment temperature line
        let envY = toScreenY(envTemp)
        var envLine = Path()
        envLine.move(to: CGPoint(x: graphLeft, y: envY))
        envLine.addLine(to: CGPoint(x: graphRight, y: envY))
        context.stroke(envLine, with: .color(.cyan.opacity(0.3)),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        let envLabel = Text("T\u{2091}\u{2099}\u{1D65} = \(Int(envTemp))\u{00B0}C")
            .font(.system(size: 10))
            .foregroundColor(.cyan.opacity(0.5))
        context.draw(envLabel, at: CGPoint(x: graphRight - 40, y: envY - 12))

        // Exponential cooling curve (theoretical)
        if showExponential {
            var curve = Path()
            var started = false
            for screenX in stride(from: graphLeft, through: graphRight, by: 1) {
                let t = (screenX - graphLeft) / (graphRight - graphLeft) * timeMax
                let temp = currentTemperature(at: t)
                let y = toScreenY(temp)

                if !started {
                    curve.move(to: CGPoint(x: screenX, y: y))
                    started = true
                } else {
                    curve.addLine(to: CGPoint(x: screenX, y: y))
                }
            }
            context.stroke(curve, with: .color(.orange.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
        }

        // Linear cooling comparison
        if showLinearComparison {
            let linearRate = coolingRate * (initialTemp - envTemp)
            var linearCurve = Path()
            var started = false
            for screenX in stride(from: graphLeft, through: graphRight, by: 1) {
                let t = (screenX - graphLeft) / (graphRight - graphLeft) * timeMax
                let temp = max(envTemp, initialTemp - linearRate * t)
                let y = toScreenY(temp)

                if !started {
                    linearCurve.move(to: CGPoint(x: screenX, y: y))
                    started = true
                } else {
                    linearCurve.addLine(to: CGPoint(x: screenX, y: y))
                }
            }
            context.stroke(linearCurve, with: .color(.green.opacity(0.3)),
                           style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            let linLabel = Text("Linear (comparison)")
                .font(.system(size: 9))
                .foregroundColor(.green.opacity(0.4))
            context.draw(linLabel, at: CGPoint(x: w * 0.7, y: graphTop + 30))
        }

        // Data points (recorded during simulation)
        for point in dataPoints {
            let px = toScreenX(point.time)
            let py = toScreenY(point.temp)
            let dotRect = CGRect(x: px - 2.5, y: py - 2.5, width: 5, height: 5)

            // Color based on temperature (hot = red, cool = blue)
            let tempNorm = (point.temp - envTemp) / (initialTemp - envTemp)
            let dotColor = Color(red: tempNorm, green: 0.2, blue: 1.0 - tempNorm)
            context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
        }

        // Current temperature marker
        if time > 0 {
            let currentTemp = currentTemperature(at: time)
            let curX = toScreenX(time)
            let curY = toScreenY(currentTemp)

            // Crosshair
            var crossH = Path()
            crossH.move(to: CGPoint(x: curX - 8, y: curY))
            crossH.addLine(to: CGPoint(x: curX + 8, y: curY))
            crossH.move(to: CGPoint(x: curX, y: curY - 8))
            crossH.addLine(to: CGPoint(x: curX, y: curY + 8))
            context.stroke(crossH, with: .color(.white.opacity(0.6)), lineWidth: 1.5)

            // Glow
            let glowRect = CGRect(x: curX - 6, y: curY - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: glowRect), with: .color(.orange.opacity(0.3)))

            // Temperature readout
            let tempText = Text(String(format: "%.1f\u{00B0}C", currentTemp))
                .font(.system(size: 12, weight: .bold).monospaced())
                .foregroundColor(.orange)
            context.draw(tempText, at: CGPoint(x: curX + 30, y: curY - 10))

            let timeText = Text(String(format: "t = %.1fs", time))
                .font(.system(size: 10).monospaced())
                .foregroundColor(.white.opacity(0.5))
            context.draw(timeText, at: CGPoint(x: curX + 30, y: curY + 5))
        }

        // Thermometer icon (left side visual)
        let thermoX = w * 0.03
        let thermoTop = graphTop + 20
        let thermoBottom = graphBottom - 20
        let thermoW = 12.0

        // Bulb
        let bulbR = thermoW
        let bulbRect = CGRect(x: thermoX - bulbR, y: thermoBottom - bulbR,
                               width: bulbR * 2, height: bulbR * 2)
        context.fill(Path(ellipseIn: bulbRect), with: .color(.red.opacity(0.8)))

        // Tube
        let tubeRect = CGRect(x: thermoX - thermoW / 4, y: thermoTop,
                               width: thermoW / 2, height: thermoBottom - thermoTop - bulbR)
        context.fill(Path(roundedRect: tubeRect, cornerRadius: 2),
                     with: .color(Color(white: 0.2)))

        // Mercury level
        if time > 0 {
            let currentTemp = currentTemperature(at: time)
            let level = (currentTemp - tempMin) / (tempMax - tempMin)
            let mercuryTop = thermoBottom - bulbR - level * (thermoBottom - thermoTop - bulbR - 10)
            let mercuryRect = CGRect(x: thermoX - thermoW / 4 + 1, y: mercuryTop,
                                      width: thermoW / 2 - 2,
                                      height: thermoBottom - bulbR - mercuryTop)
            context.fill(Path(mercuryRect), with: .color(.red.opacity(0.7)))
        }

        // Title
        let title = Text("Newton's Law of Cooling")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
        context.draw(title, at: CGPoint(x: w * 0.5, y: 20))

        // Formula
        let formula = Text("T(t) = T\u{2091}\u{2099}\u{1D65} + (T\u{2080} \u{2212} T\u{2091}\u{2099}\u{1D65}) \u{00B7} e^(\u{2212}kt)")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.3))
        context.draw(formula, at: CGPoint(x: w * 0.5, y: h - 12))

        // Axis labels
        let xLabel = Text("Time (seconds)")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.4))
        context.draw(xLabel, at: CGPoint(x: (graphLeft + graphRight) / 2, y: graphBottom + 25))

        let yLabel = Text("Temperature (\u{00B0}C)")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.4))
        context.draw(yLabel, at: CGPoint(x: graphLeft + 35, y: graphTop - 10))

        // Legend
        if showExponential {
            var legLine = Path()
            legLine.move(to: CGPoint(x: w * 0.65, y: graphTop + 10))
            legLine.addLine(to: CGPoint(x: w * 0.65 + 20, y: graphTop + 10))
            context.stroke(legLine, with: .color(.orange.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
            let legLabel = Text("Exponential (Newton)")
                .font(.system(size: 9))
                .foregroundColor(.orange.opacity(0.5))
            context.draw(legLabel, at: CGPoint(x: w * 0.65 + 65, y: graphTop + 10))
        }
    }
}
