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
    
    enum TexturePos: Int {
        case bottomLeft = 0
        case bottomRight = 3
        case topLeft = 2
        case topRight = 1
    }
    
    var pipelineState: MTLRenderPipelineState?
    var texture: MTLTexture?
    var vertexProgram: MTLFunction?
    var fragmentProgram: MTLFunction?
    var vertices : [TVertex] = []
    var vertexBuffer: MTLBuffer?
    var image: UIImage?
    weak var canvas: Canvas!
    
    init(url: URL, midPosition: CGPoint, canvas: Canvas) {
        self.canvas = canvas
        image = drawPDFfromURL(url: url)
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        /*let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Uint, width: Int (pdfIMG!.size.width), height: Int (pdfIMG!.size.height), mipmapped: false)
        if let pdfIMG = pdfIMG {
            //texture = try! textureLoader.newTexture(cgImage: pdfIMG.cgImage!)
            texture = Renderer.device.makeTexture(descriptor: textureDescriptor)
        }*/
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        /*if let textureURL = Bundle.main.url(forResource: "photo2", withExtension: "jpg"){
            do {
                texture = try textureLoader.newTexture(URL: textureURL, options: [:])
            }catch{
                print("not created")
            }
        }*/
        if let img = image?.cgImage {
            vertices = generateVertex(size: image!.size, maxSize: CGSize(width: 800, height: 800), midPoint: midPosition)
            do {
                //texture = try textureLoader.newTexture(data: img, options: [:])
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
    
    
    func generateVertex(size: CGSize, maxSize: CGSize, midPoint: CGPoint) -> [TVertex] {
        //let maxSize = CGSize(width: max(size.width, maxSize.width), height: max(size.height, maxSize.height))
        let maxSize = CGSize(width: size.width / 2, height: size.height / 2)
        //print(midPoint)
        let bl = TVertex(position: canvas.metalView.convertToSIMD3(x: midPoint.x - maxSize.width / 2, y: midPoint.y - maxSize.height / 2), texturePosition: SIMD2<Float>(0,1))
        let br = TVertex(position: canvas.metalView.convertToSIMD3(x: midPoint.x + maxSize.width / 2, y: midPoint.y - maxSize.height / 2), texturePosition: SIMD2<Float>(1,1))
        let tl = TVertex(position: canvas.metalView.convertToSIMD3(x: midPoint.x - maxSize.width / 2, y: midPoint.y + maxSize.height / 2), texturePosition: SIMD2<Float>(0,0))
        let tr = TVertex(position: canvas.metalView.convertToSIMD3(x: midPoint.x + maxSize.width / 2, y: midPoint.y + maxSize.height / 2), texturePosition: SIMD2<Float>(1,0))
        return [bl, tr, tl, br, tr, bl]
    }
    
    //func generateFrameVertices(
    
    func drawPDFfromURL(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let scale = 5.0
        let scaledRect = CGRect(x: pageRect.minX, y: pageRect.minY, width: pageRect.width * scale, height: pageRect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: scaledRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(scaledRect)

            ctx.cgContext.translateBy(x: 0.0, y: scaledRect.size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
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
