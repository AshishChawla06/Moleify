#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Vertex Shader
vertex VertexOutput basic_vertex(uint vertexID [[vertex_id]]) {
    VertexOutput out;
    // Fullscreen quad
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

// MARK: - Metal Fragment Shader for Ambient Liquid Glass
fragment float4 liquid_glass_fragment(VertexOutput in [[stage_in]],
                                       constant float &time [[buffer(0)]],
                                       constant float2 &resolution [[buffer(1)]]) {
    float2 uv = in.texCoord;
    
    // Wave motion calculations
    float wave1 = sin(uv.x * 6.0 + time * 0.8) * 0.04;
    float wave2 = cos(uv.y * 5.0 - time * 0.6) * 0.03;
    float wave3 = sin((uv.x + uv.y) * 8.0 + time * 1.2) * 0.02;
    
    float intensity = 0.5 + 0.5 * (wave1 + wave2 + wave3);
    
    // macOS Sequoia Dark Metallic Cyan / Violet / Slate Gradient Palette
    float3 col1 = float3(0.06, 0.12, 0.22); // Deep Ocean Navy
    float3 col2 = float3(0.15, 0.25, 0.45); // Vibrant Cyan Slate
    float3 col3 = float3(0.28, 0.16, 0.42); // Subtle Amethyst Accent
    
    float mixFactor = uv.y + wave1;
    float3 finalColor = mix(col1, col2, smoothstep(0.0, 1.0, mixFactor));
    finalColor = mix(finalColor, col3, intensity * 0.3);
    
    // Highlight glow border
    float distCenter = length(uv - float2(0.5, 0.5));
    finalColor += float3(0.08, 0.15, 0.25) * (1.0 - smoothstep(0.2, 0.7, distCenter));
    
    return float4(finalColor, 0.45); // Semi-translucent for SwiftUI material glass blend
}

// MARK: - Metal Fragment Shader for CPU/Memory Dynamic Particle Gauge Wave
fragment float4 particle_gauge_fragment(VertexOutput in [[stage_in]],
                                         constant float &time [[buffer(0)]],
                                         constant float &usageValue [[buffer(1)]],
                                         constant float3 &themeColor [[buffer(2)]]) {
    float2 uv = in.texCoord - float2(0.5, 0.5);
    float dist = length(uv);
    float angle = atan2(uv.y, uv.x);
    
    // Circular arc ring bounds
    float innerRadius = 0.32;
    float outerRadius = 0.44;
    
    // Ring mask
    float ringMask = smoothstep(innerRadius - 0.01, innerRadius, dist) - smoothstep(outerRadius, outerRadius + 0.01, dist);
    
    // Normalized angle 0 to 1
    float normAngle = (angle + 3.14159265) / (2.0 * 3.14159265);
    
    // Dynamic fill percentage based on usageValue
    float fillMask = step(normAngle, usageValue);
    
    // High-frequency particle ripple pulse along the filled arc
    float particlePulse = sin(angle * 16.0 + time * 4.0) * 0.15 + 0.85;
    float glow = smoothstep(outerRadius + 0.05, innerRadius - 0.05, dist);
    
    float3 activeColor = themeColor * particlePulse;
    float3 inactiveColor = float3(0.12, 0.14, 0.18);
    
    float3 col = mix(inactiveColor, activeColor, fillMask * ringMask);
    col += themeColor * (fillMask * glow * 0.15); // Ambient inner glow
    
    float alpha = ringMask * 0.9 + glow * 0.2;
    return float4(col, clamp(alpha, 0.0, 1.0));
}
