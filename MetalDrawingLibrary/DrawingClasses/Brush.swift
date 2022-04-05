//
//  Brush.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import Metal
import simd

struct Vertex {
    var position: SIMD3<Float>
    var force: Float
    var color: SIMD4<Float>
}

class Brush {
    var pipelineState: MTLRenderPipelineState?
    var texture: MTLTexture?
    var vertexProgram: MTLFunction?
    var fragmentProgram: MTLFunction?
    var color: SIMD4<Float>
    var lineWidth: Float = 40.0
    var minWidth : Float = 4.0
    
    init(color: SIMD4<Float>) {
        self.color = color
        let vertexProgram = createVertexProgram()
        let fragmentProgram = createFragmentProgram()
        guard let vertexProgram = vertexProgram, let fragmentProgram = fragmentProgram else { fatalError("VertexProgram or FragmentProgram not available") }

        let descriptor = createPipelineDescriptor(vertexProgram: vertexProgram, fragmentProgram: fragmentProgram)
        let vertexDescriptor = createVertexDescriptor()
        descriptor.vertexDescriptor = vertexDescriptor
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("The device could not create the Render Pipeline State")
        }
       
    }
    
    func createVertexProgram() -> MTLFunction?{
        Renderer.library.makeFunction(name: "basic_vertex")
    }
    
    func createFragmentProgram() -> MTLFunction? {
        Renderer.library.makeFunction(name: "basic_fragment")
    }
    
    func createPipelineDescriptor(vertexProgram: MTLFunction, fragmentProgram: MTLFunction) -> MTLRenderPipelineDescriptor{
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.sampleCount = MetalView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        return pipelineDescriptor
    }
    
    func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = .float3
        
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.size
        vertexDescriptor.attributes[1].format = .float
        
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = 0x20
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        return vertexDescriptor
    }
    
    
}
