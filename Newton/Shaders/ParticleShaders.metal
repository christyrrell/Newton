#include <metal_stdlib>
using namespace metal;

// Must match GPUParticle in MetalParticleRenderer.swift
struct Particle {
    float2 position;
    float2 velocity;
    float life;
    float maxLife;
    float size;
    uint alive;
};

// Must match GPUUniforms in MetalParticleRenderer.swift
struct Uniforms {
    float2 canvasSize;
    float gravity;
    float wind;
    float dt;
    uint colorMode;
    uint particleCount;
    uint _pad;
};

// ---------------------------------------------------------------------------
// Compute kernel: update all particles in parallel on GPU
// ---------------------------------------------------------------------------
kernel void updateParticles(
    device Particle *particles [[buffer(0)]],
    constant Uniforms &u [[buffer(1)]],
    uint id [[thread_position_in_grid]])
{
    if (id >= u.particleCount) return;

    device Particle &p = particles[id];
    if (p.alive == 0) return;

    float dt = u.dt;

    // Gravity (downward in screen coords)
    p.velocity.y += u.gravity * dt;

    // Wind (horizontal)
    p.velocity.x += u.wind * dt;

    // Integrate position
    p.position += p.velocity * dt;

    // Age the particle
    p.life += dt;

    // Kill if expired or out of bounds
    if (p.life > p.maxLife ||
        p.position.y > u.canvasSize.y + 20.0 ||
        p.position.x < -20.0 ||
        p.position.x > u.canvasSize.x + 20.0) {
        p.alive = 0;
    }
}

// ---------------------------------------------------------------------------
// Render pipeline
// ---------------------------------------------------------------------------
struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
};

// HSV → RGB (for rainbow mode)
static float3 hsv2rgb(float h, float s, float v) {
    float c = v * s;
    float hp = h * 6.0;
    float x = c * (1.0 - abs(fmod(hp, 2.0) - 1.0));
    float m = v - c;
    float3 rgb;
    if      (hp < 1.0) rgb = float3(c, x, 0);
    else if (hp < 2.0) rgb = float3(x, c, 0);
    else if (hp < 3.0) rgb = float3(0, c, x);
    else if (hp < 4.0) rgb = float3(0, x, c);
    else if (hp < 5.0) rgb = float3(x, 0, c);
    else                rgb = float3(c, 0, x);
    return rgb + m;
}

vertex VertexOut particleVertex(
    device const Particle *particles [[buffer(0)]],
    constant Uniforms &u [[buffer(1)]],
    uint vid [[vertex_id]])
{
    VertexOut out;
    Particle p = particles[vid];

    // Dead particles → off-screen, zero-size (GPU skips rasterization)
    if (p.alive == 0) {
        out.position  = float4(-10.0, -10.0, 0.0, 1.0);
        out.pointSize = 0.0;
        out.color     = float4(0.0);
        return out;
    }

    // Pixel → NDC
    float2 ndc;
    ndc.x =  (p.position.x / u.canvasSize.x) * 2.0 - 1.0;
    ndc.y = 1.0 - (p.position.y / u.canvasSize.y) * 2.0;

    out.position  = float4(ndc, 0.0, 1.0);
    out.pointSize = p.size * 2.0;

    // Fade with age
    float alpha = max(0.0f, 1.0f - p.life / p.maxLife);
    float speed = length(p.velocity);

    float3 col;
    if (u.colorMode == 0) {
        // Velocity-based: fast → red/white, slow → blue
        float sn = min(1.0f, speed / 500.0f);
        col = float3(sn, 0.3 + (1.0 - sn) * 0.5, 1.0 - sn);
    } else if (u.colorMode == 1) {
        // Height-based: high → cyan, low → warm
        float hn = 1.0 - clamp(p.position.y / u.canvasSize.y, 0.0f, 1.0f);
        col = float3(1.0 - hn * 0.5, hn * 0.8, hn);
    } else {
        // Rainbow: hue cycles with life + vertex index
        float hue = fmod(p.life * 0.3 + float(vid) * 0.001, 1.0);
        col = hsv2rgb(hue, 0.8, 0.9);
    }

    out.color = float4(col, alpha);
    return out;
}

fragment float4 particleFragment(
    VertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]])
{
    // Circular point sprite with soft edge
    float dist = length(pointCoord - float2(0.5));
    if (dist > 0.5) discard_fragment();

    float edge = 1.0 - smoothstep(0.3, 0.5, dist);
    return float4(in.color.rgb, in.color.a * edge);
}
