//
//  Texture.swift
//  MetalDrawingLibrary
//
//  Created by Tom Rudnick on 30.03.22.
//

import Foundation
import Metal
import simd
import UIKit
import MetalKit

struct TVertex{
    var position : SIMD3<Float>
    var texturePosition: SIMD2<Float>
}

class Texture{
    var pipelineState: MTLRenderPipelineState?
    var texture: MTLTexture?
    var vertexProgram: MTLFunction?
    var fragmentProgram: MTLFunction?
    var vertices : [TVertex] = [
        TVertex(position: SIMD3<Float>(0,0.684,0), texturePosition: SIMD2<Float>(0,1)),
        TVertex(position: SIMD3<Float>(0,0,0), texturePosition: SIMD2<Float>(0,0)),
        TVertex(position: SIMD3<Float>(0.549,0,0), texturePosition: SIMD2<Float>(1,0)),
        TVertex(position: SIMD3<Float>(0.549,0,0), texturePosition: SIMD2<Float>(1,0)),
        TVertex(position: SIMD3<Float>(0.549,0.684,0), texturePosition: SIMD2<Float>(1,1)),
        TVertex(position: SIMD3<Float>(0,0.684,0), texturePosition: SIMD2<Float>(0,1))
    ]
    var vertexBuffer: MTLBuffer?
    
    init(url: URL) {
        let pdfIMG = drawPDFfromURL(url: url)
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        /*let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Uint, width: Int (pdfIMG!.size.width), height: Int (pdfIMG!.size.height), mipmapped: false)
        if let pdfIMG = pdfIMG {
            //texture = try! textureLoader.newTexture(cgImage: pdfIMG.cgImage!)
            texture = Renderer.device.makeTexture(descriptor: textureDescriptor)
        }*/
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        /*if let textureURL = Bundle.main.url(forResource: "photo", withExtension: "jpg"){
            do {
                texture = try textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
            }catch{
                print("not created")
            }
        }*/
        let img2 = UIImage(data: pdfIMG!.pngData()!)
        
        if let img = img2?.cgImage {
            print("COLOR Space \(img.colorSpace!)")
            do {
                //texture = try textureLoader.newTexture(data: img, options: textureLoaderOptions)
                texture = try textureLoader.newTexture(cgImage: img, options: textureLoaderOptions)
            } catch {
                print(error.localizedDescription)
                fatalError()
            }
            
        }
        
        /*let region = MTLRegionMake2D(0, 0, Int(pdfIMG!.size.width), Int(pdfIMG!.size.height))
        texture!.replace(region: region, mipmapLevel: 0, withBytes: &pdfIMG!, bytesPerRow: 8 * Int(pdfIMG!.size.width))*/
        
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
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<TVertex>.stride * vertices.count, options: [])
        
       
    }
    
    func drawPDFfromURL(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }

    func createVertexProgram() -> MTLFunction?{
        Renderer.library.makeFunction(name: "tvertex")
    }
    
    func createFragmentProgram() -> MTLFunction? {
        Renderer.library.makeFunction(name: "tfragment")
    }
    
    func createPipelineDescriptor(vertexProgram: MTLFunction, fragmentProgram: MTLFunction) -> MTLRenderPipelineDescriptor{
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.sampleCount = MetalView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        
        
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
        vertexDescriptor.attributes[1].format = .float2
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<TVertex>.stride
        return vertexDescriptor
    }
}
