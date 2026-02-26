import SwiftUI
import MetalKit

/// GPU-accelerated particle fountain demonstrating gravity, acceleration,
/// and drag.  Physics runs on a Metal compute shader; rendering uses
/// point-sprite instancing with additive blending — all on the GPU.
struct ParticleGravityView: View {
    @State private var gravity: Double = 400
    @State private var emitRate: Double = 8
    @State private var initialSpeed: Double = 350
    @State private var spreadAngle: Double = 30
    @State private var colorMode: Int = 0
    @State private var windForce: Double = 0
    @State private var particleCount: Int = 0
    @State private var rendererBox = RendererBox()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Metal rendering surface
                MetalParticleNSView(
                    gravity: Float(gravity),
                    wind: Float(windForce),
                    emitRate: Int(emitRate),
                    initialSpeed: Float(initialSpeed),
                    spreadAngle: Float(spreadAngle),
                    colorMode: UInt32(colorMode),
                    rendererBox: rendererBox
                )

                // Ground reference line
                GeometryReader { geo in
                    Path { path in
                        let y = geo.size.height * 0.85
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .allowsHitTesting(false)

                // HUD text overlays
                VStack {
                    Text("Particle Gravity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 16)

                    Spacer()

                    HStack {
                        Text("\(particleCount) particles  \u{2014}  Metal Compute + Render")
                            .font(.system(size: 10).monospaced())
                            .foregroundColor(.white.opacity(0.3))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)

                    Text("F = ma  \u{2014}  a = g + F\u{1D65}/m")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.bottom, 8)
                }
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])

            // Controls
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

                VStack(alignment: .leading, spacing: 2) {
                    Text("Emit Rate: \(Int(emitRate))")
                        .font(.caption).foregroundStyle(.secondary)
                    Slider(value: $emitRate, in: 1...30, step: 1)
                        .frame(width: 100)
                }

                Picker("Color", selection: $colorMode) {
                    Text("Velocity").tag(0)
                    Text("Height").tag(1)
                    Text("Rainbow").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()
            }
            .padding()
        }
        .onReceive(
            Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
        ) { _ in
            particleCount = rendererBox.renderer?.liveParticleCount ?? 0
        }
    }
}

// MARK: - Bridge to hold renderer reference across SwiftUI updates

final class RendererBox {
    var renderer: MetalParticleRenderer?
}

// MARK: - NSViewRepresentable wrapping MTKView

struct MetalParticleNSView: NSViewRepresentable {
    var gravity: Float
    var wind: Float
    var emitRate: Int
    var initialSpeed: Float
    var spreadAngle: Float
    var colorMode: UInt32
    var rendererBox: RendererBox

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 120   // ProMotion on Apple Silicon
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.layer?.isOpaque = true

        if let renderer = MetalParticleRenderer(mtkView: view) {
            view.delegate = renderer
            rendererBox.renderer = renderer
        }

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        guard let r = rendererBox.renderer else { return }
        r.gravity      = gravity
        r.wind         = wind
        r.emitRate     = emitRate
        r.initialSpeed = initialSpeed
        r.spreadAngle  = spreadAngle
        r.colorMode    = colorMode
    }
}
