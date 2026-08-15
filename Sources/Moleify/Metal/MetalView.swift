import SwiftUI
import MetalKit
import Metal

// MARK: - Metal Shader Source String
public enum MetalShaderSource {
    public static let code: String = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    vertex VertexOut basic_vertex(uint vertexID [[vertex_id]]) {
        float2 positions[4] = {
            float2(-1.0, -1.0),
            float2( 1.0, -1.0),
            float2(-1.0,  1.0),
            float2( 1.0,  1.0)
        };
        
        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = positions[vertexID] * 0.5 + 0.5;
        return out;
    }

    fragment float4 liquid_glass_fragment(VertexOut in [[stage_in]],
                                          constant float &time [[buffer(0)]],
                                          constant float2 &resolution [[buffer(1)]]) {
        float2 uv = in.uv;
        float wave1 = sin(uv.x * 6.0 + time * 0.8) * 0.05;
        float wave2 = cos(uv.y * 5.0 - time * 0.6) * 0.05;
        float glow = 0.05 + 0.03 * sin(time + uv.x * 3.0);
        return float4(0.02 + glow, 0.04 + glow * 1.2, 0.08 + glow * 1.5, 0.25);
    }

    fragment float4 particle_gauge_fragment(VertexOut in [[stage_in]],
                                            constant float &time [[buffer(0)]],
                                            constant float &usageValue [[buffer(1)]],
                                            constant float3 &themeColor [[buffer(2)]]) {
        float2 uv = in.uv - 0.5;
        float dist = length(uv);
        float angle = atan2(uv.y, uv.x);
        float normAngle = (angle + 3.14159265) / (2.0 * 3.14159265);
        
        float ringInner = 0.32;
        float ringOuter = 0.42;
        
        if (dist >= ringInner && dist <= ringOuter) {
            if (normAngle <= usageValue) {
                float pulse = 0.85 + 0.15 * sin(time * 4.0 + normAngle * 10.0);
                return float4(themeColor * pulse, 0.9);
            } else {
                return float4(1.0, 1.0, 1.0, 0.08);
            }
        }
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    """
}

// MARK: - Metal Ambient Liquid Glass Background View
public struct MetalBackgroundView: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.delegate = context.coordinator
        mtkView.enableSetNeedsDisplay = false
        return mtkView
    }
    
    public func updateNSView(_ nsView: MTKView, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        var startTime: Date = Date()
        
        override init() {
            super.init()
            self.device = MTLCreateSystemDefaultDevice()
            guard let device = device else { return }
            self.commandQueue = device.makeCommandQueue()
            
            setupPipeline(device: device)
        }
        
        private func setupPipeline(device: MTLDevice) {
            let library = (try? device.makeLibrary(source: MetalShaderSource.code, options: nil)) ?? device.makeDefaultLibrary()
            guard let library = library else { return }
            
            let vertexFunction = library.makeFunction(name: "basic_vertex")
            let fragmentFunction = library.makeFunction(name: "liquid_glass_fragment")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            
            self.pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        public func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pipelineState = pipelineState,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandQueue = commandQueue else { return }
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            
            var time = Float(Date().timeIntervalSince(startTime))
            var resolution = SIMD2<Float>(Float(view.bounds.width), Float(view.bounds.height))
            
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
            encoder?.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
            
            encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder?.endEncoding()
            
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}

// MARK: - Metal Hardware-Accelerated Particle Wave Gauge View
public struct MetalParticleGaugeView: NSViewRepresentable {
    public var usageValue: Double // 0.0 to 1.0
    public var themeColor: SIMD3<Float> // RGB 0..1
    
    public init(usageValue: Double, themeColor: SIMD3<Float> = SIMD3<Float>(0.2, 0.7, 1.0)) {
        self.usageValue = usageValue
        self.themeColor = themeColor
    }
    
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.delegate = context.coordinator
        return mtkView
    }
    
    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.usageValue = Float(usageValue)
        context.coordinator.themeColor = themeColor
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(usageValue: Float(usageValue), themeColor: themeColor)
    }
    
    public class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        var startTime: Date = Date()
        
        var usageValue: Float
        var themeColor: SIMD3<Float>
        
        init(usageValue: Float, themeColor: SIMD3<Float>) {
            self.usageValue = usageValue
            self.themeColor = themeColor
            super.init()
            
            self.device = MTLCreateSystemDefaultDevice()
            guard let device = device else { return }
            self.commandQueue = device.makeCommandQueue()
            setupPipeline(device: device)
        }
        
        private func setupPipeline(device: MTLDevice) {
            let library = (try? device.makeLibrary(source: MetalShaderSource.code, options: nil)) ?? device.makeDefaultLibrary()
            guard let library = library else { return }
            
            let vertexFunction = library.makeFunction(name: "basic_vertex")
            let fragmentFunction = library.makeFunction(name: "particle_gauge_fragment")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            
            self.pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        public func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pipelineState = pipelineState,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandQueue = commandQueue else { return }
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            
            var time = Float(Date().timeIntervalSince(startTime))
            var val = usageValue
            var color = themeColor
            
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
            encoder?.setFragmentBytes(&val, length: MemoryLayout<Float>.size, index: 1)
            encoder?.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.size, index: 2)
            
            encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder?.endEncoding()
            
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
