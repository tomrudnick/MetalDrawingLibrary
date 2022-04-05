//
//  Rendere.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import MetalKit
import simd
import Alloy

class Renderer: NSObject, RendererDelegate {
   
    static var device: MTLDevice!
    static var library: MTLLibrary!
    
    var commandQueue: MTLCommandQueue!
    var colorPixelFormat: MTLPixelFormat!
    var metalLayer: CAMetalLayer!
    var metalView: MetalView!
    var canvas: Canvas!
    var texture: MTLTexture!
    var depthState: MTLDepthStencilState!
    var clearColor: MTLClearColor!
    var metalContext: MTLContext!
    var cgContext: CGContext!
    
    
    init(metalView: MetalView, canvas: Canvas) {
        super.init()
        Renderer.device = MTLCreateSystemDefaultDevice()
        self.canvas = canvas
        self.metalView = metalView
        self.metalLayer = metalView.metalLayer
        metalLayer.device = Renderer.device
        metalLayer.framebufferOnly = true
        metalContext = try! MTLContext(device: metalLayer.device!)
        commandQueue = Renderer.device.makeCommandQueue()
        Renderer.library = Renderer.device.makeDefaultLibrary()
        texture = makeTexture()
        
        let depthStencilDesc = MTLDepthStencilDescriptor()
        depthStencilDesc.depthCompareFunction = .always
        depthStencilDesc.isDepthWriteEnabled = false
        depthState = metalLayer.device!.makeDepthStencilState(descriptor: depthStencilDesc)!
        
        self.clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0)
    }
    
    func makeTexture() -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2DMultisample
        textureDescriptor.width = Int(CGFloat(metalView.viewportSize.x) * metalView.scale)
        textureDescriptor.height = Int(CGFloat(metalView.viewportSize.y) * metalView.scale)
        textureDescriptor.sampleCount = MetalView.sampleCount
        textureDescriptor.pixelFormat = .bgra8Unorm
        let newTexture = metalLayer.device?.makeTexture(descriptor: textureDescriptor)
        if let newTexture = newTexture {
            return newTexture
        } else {
            fatalError("Creating Texture failed")
        }
    }
    //when the Viewportsize changes the texture needs to be recreated
    func recreateTexture() {
        self.texture = makeTexture()
    }
    
    //called my MetalView using the delegatePattern
    func render() {
        //print("Render Called")
        let commandBuffer = commandQueue.makeCommandBuffer()
        guard let drawable = metalLayer.nextDrawable(), let commandBuffer = commandBuffer else { fatalError("Rendering failed")}
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        let renderEncoder = commandBuffer
          .makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(metalView.viewportSize.x) * metalView.scale, height: Double(metalView.viewportSize.y) * metalView.scale, znear: 0.0, zfar: 1.0))
        renderEncoder.setDepthStencilState(depthState)
        //print("X: \(metalView.viewportSize.x) Y: \(metalView.viewportSize.y) ")
        if let pdf = canvas.pdf {
            renderEncoder.setRenderPipelineState(pdf.pipelineState!)
            renderEncoder.setVertexBytes(&metalView.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            renderEncoder.setVertexBuffer(pdf.vertexBuffer!, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(pdf.texture!, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: pdf.vertices.count)
        }
        
        var addedLine = false
        var zoom : vector_float2 = SIMD2<Float>(canvas.zoom, canvas.zoom)
        var zoomPoint : vector_float2 = canvas.zoomPoint
        if let currentLine = canvas.activeLine {
            canvas.lines.append(currentLine)
            addedLine = true
        }
        for line in canvas.lines {
            if let vertexBuffer = line.vertexBuffer, let pipelineState = line.brush.pipelineState {
                renderEncoder.setRenderPipelineState(pipelineState)
                //renderEncoder.setDepthStencilState(depthState)
                renderEncoder.setVertexBytes(&metalView.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                renderEncoder.setVertexBytes(&zoom, length: MemoryLayout<vector_float2>.stride, index: 2)
                renderEncoder.setVertexBytes(&zoomPoint, length: MemoryLayout<vector_float2>.stride, index: 3)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: line.vertexPoints.count)
                //renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: line.indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            }
        }
        if addedLine {
            canvas.lines.remove(at: canvas.lines.count - 1)
        }
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    
}
