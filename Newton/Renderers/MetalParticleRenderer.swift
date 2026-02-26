import MetalKit
import simd

// Must match Particle in ParticleShaders.metal (32 bytes)
struct GPUParticle {
    var position: SIMD2<Float> = .zero   // 8
    var velocity: SIMD2<Float> = .zero   // 8
    var life: Float = 0                  // 4
    var maxLife: Float = 0               // 4
    var size: Float = 0                  // 4
    var alive: UInt32 = 0                // 4
}

// Must match Uniforms in ParticleShaders.metal (32 bytes)
struct GPUUniforms {
    var canvasSize: SIMD2<Float> = .zero
    var gravity: Float = 400
    var wind: Float = 0
    var dt: Float = 1.0 / 60.0
    var colorMode: UInt32 = 0
    var particleCount: UInt32 = 0
    var _pad: UInt32 = 0
}

/// Metal-based particle renderer.
///
/// Physics runs on the GPU via a compute shader; rendering uses
/// point-sprite instancing with additive blending.  The particle
/// buffer uses `.storageModeShared` — zero-copy on Apple Silicon.
final class MetalParticleRenderer: NSObject, MTKViewDelegate {

    // MARK: - Metal objects
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let computePipeline: MTLComputePipelineState
    private let renderPipeline: MTLRenderPipelineState
    private let particleBuffer: MTLBuffer

    // MARK: - Particle state
    let maxParticles = 8_000
    private let particles: UnsafeMutablePointer<GPUParticle>
    private var nextEmitIndex = 0
    private var frameCount = 0

    // MARK: - Tunables (driven by SwiftUI controls)
    var gravity: Float = 400
    var wind: Float = 0
    var emitRate: Int = 8
    var initialSpeed: Float = 350
    var spreadAngle: Float = 30
    var colorMode: UInt32 = 0
    var canvasSize: SIMD2<Float> = .zero
    var liveParticleCount: Int = 0

    // MARK: - Init

    init?(mtkView: MTKView) {
        guard let device = mtkView.device,
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary()
        else { return nil }

        self.device = device
        self.commandQueue = queue

        // ---- Compute pipeline ----
        guard let computeFn = library.makeFunction(name: "updateParticles"),
              let computePipe = try? device.makeComputePipelineState(function: computeFn)
        else { return nil }
        self.computePipeline = computePipe

        // ---- Render pipeline ----
        guard let vertFn = library.makeFunction(name: "particleVertex"),
              let fragFn = library.makeFunction(name: "particleFragment")
        else { return nil }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertFn
        desc.fragmentFunction = fragFn
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        // Additive blending — overlapping particles glow brighter
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .one
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let renderPipe = try? device.makeRenderPipelineState(descriptor: desc)
        else { return nil }
        self.renderPipeline = renderPipe

        // ---- Particle buffer (unified memory — zero-copy on Apple Silicon) ----
        let bufSize = MemoryLayout<GPUParticle>.stride * maxParticles
        guard let buf = device.makeBuffer(length: bufSize, options: .storageModeShared)
        else { return nil }
        self.particleBuffer = buf
        self.particles = buf.contents()
            .bindMemory(to: GPUParticle.self, capacity: maxParticles)

        super.init()

        // Clear buffer
        for i in 0..<maxParticles { particles[i] = GPUParticle() }
    }

    // MARK: - CPU-side emission

    /// Emit new particles by writing directly into the shared buffer.
    /// Runs on the CPU — trivial cost thanks to unified memory.
    private func emitParticles() {
        guard canvasSize.x > 0, canvasSize.y > 0 else { return }

        let ex = canvasSize.x * 0.5
        let ey = canvasSize.y * 0.85

        for _ in 0..<emitRate {
            let angleDeg = Float.random(in: -spreadAngle...spreadAngle)
            let angle = Float.pi / 2.0 + angleDeg * (.pi / 180.0)
            let speed = initialSpeed * Float.random(in: 0.8...1.2)

            var p = GPUParticle()
            p.position = SIMD2(ex + Float.random(in: -5...5), ey)
            p.velocity = SIMD2(cos(angle) * speed, -sin(angle) * speed)
            p.life     = 0
            p.maxLife  = Float.random(in: 3...6)
            p.size     = Float.random(in: 2...5)
            p.alive    = 1

            particles[nextEmitIndex] = p
            nextEmitIndex = (nextEmitIndex + 1) % maxParticles
        }
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        canvasSize = SIMD2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard canvasSize.x > 0, canvasSize.y > 0 else { return }

        frameCount += 1

        // 1. Emit new particles (CPU, negligible cost)
        emitParticles()

        // 2. Build uniforms
        var uniforms = GPUUniforms()
        uniforms.canvasSize    = canvasSize
        uniforms.gravity       = gravity
        uniforms.wind          = wind
        uniforms.dt            = 1.0 / Float(view.preferredFramesPerSecond)
        uniforms.colorMode     = colorMode
        uniforms.particleCount = UInt32(maxParticles)

        guard let cmdBuf = commandQueue.makeCommandBuffer() else { return }

        // 3. GPU Compute: update every particle in parallel
        if let enc = cmdBuf.makeComputeCommandEncoder() {
            enc.setComputePipelineState(computePipeline)
            enc.setBuffer(particleBuffer, offset: 0, index: 0)
            enc.setBytes(&uniforms,
                         length: MemoryLayout<GPUUniforms>.stride,
                         index: 1)

            let tgSize = MTLSize(
                width: min(256, computePipeline.maxTotalThreadsPerThreadgroup),
                height: 1, depth: 1)
            let grid = MTLSize(width: maxParticles, height: 1, depth: 1)
            enc.dispatchThreads(grid, threadsPerThreadgroup: tgSize)
            enc.endEncoding()
        }

        // 4. GPU Render: draw every particle as a point sprite
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable
        else { return }

        rpd.colorAttachments[0].clearColor = MTLClearColor(
            red: 0, green: 0, blue: 0, alpha: 1)
        rpd.colorAttachments[0].loadAction = .clear

        if let enc = cmdBuf.makeRenderCommandEncoder(descriptor: rpd) {
            enc.setRenderPipelineState(renderPipeline)
            enc.setVertexBuffer(particleBuffer, offset: 0, index: 0)
            enc.setVertexBytes(&uniforms,
                               length: MemoryLayout<GPUUniforms>.stride,
                               index: 1)
            enc.drawPrimitives(type: .point,
                               vertexStart: 0,
                               vertexCount: maxParticles)
            enc.endEncoding()
        }

        cmdBuf.present(drawable)

        // 5. Async particle count (every ~8 frames ≈ 15 Hz at 120 fps)
        if frameCount % 8 == 0 {
            cmdBuf.addCompletedHandler { [weak self] _ in
                guard let self else { return }
                var n = 0
                for i in 0..<self.maxParticles {
                    if self.particles[i].alive != 0 { n += 1 }
                }
                DispatchQueue.main.async { self.liveParticleCount = n }
            }
        }

        cmdBuf.commit()
    }
}
