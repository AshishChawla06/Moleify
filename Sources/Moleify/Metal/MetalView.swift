import SwiftUI
import MetalKit
import Metal

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
            guard let library = device.makeDefaultLibrary() else { return }
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
            guard let library = device.makeDefaultLibrary() else { return }
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
