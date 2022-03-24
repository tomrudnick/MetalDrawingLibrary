//
//  ViewController.swift
//  metalTest
//
//  Created by Tom Rudnick on 15.03.22.
//

import UIKit
import Metal
import simd

//THIS CLASS IS DEPECRATED AND NOT USED ANYMORE

class DepViewController: UIViewController, CALayerDelegate{
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    
    var vertexData: [Float] = []
    var vertexIndex: [UInt16] = []
    
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var viewPortSize: vector_uint2 = vector_uint2(x: 1, y: 1)
    
    var points :[(Float,Float)] = []
    var pointsMem: UnsafeMutableRawPointer? = nil
    var indexMem: UnsafeMutableRawPointer? = nil
    let alignment = 0x1000
    
    
    let sampleCount = 4
    
    var indexCount = 0
    var vertexCount = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //(vertexData,vertexIndex) = computeTriangles2(points: [(0.0, 0.0), (0.1, 0.0),(0.2,0.8),(0.3,0.5),(-0.2,-0.5)], force: 0.1)
        viewPortSize.x = UInt32(self.view.frame.width)
        viewPortSize.y = UInt32(self.view.frame.height)
        //vertexData = computeTriangles(ax: 0.0, ay: 0.0, bx: 0.0, by: 0.2, force: 0.1)
        device = MTLCreateSystemDefaultDevice()
        
        // Do any additional setup after loading the view.
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        metalLayer.delegate = self
        //metalL
        //metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        //metalLayer.presentsWithTransaction = true
        
        
        view.layer.addSublayer(metalLayer)
        //let dataSize = vertexData.count * MemoryLayout<Float>.size
        let length = 100 * 4096 * MemoryLayout<Float>.stride
        let allocationsSize = (length + alignment - 1) & (~(alignment - 1))
        posix_memalign(&pointsMem, alignment, allocationsSize)
        posix_memalign(&indexMem, alignment, allocationsSize)
        vertexBuffer = device.makeBuffer(bytesNoCopy: pointsMem!, length: allocationsSize, options: [], deallocator: { pointer, _ in
            free(pointer)
        })
        indexBuffer = device.makeBuffer(bytesNoCopy: indexMem!, length: allocationsSize, options: [], deallocator: { pointer, _ in
            free(pointer)
        })
        
        //let dataSize = 100 * 4096 * MemoryLayout<Float>.
        //vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        //indexBuffer = device.makeBuffer(bytes: vertexIndex, length: 100 * 4096 * MemoryLayout<UInt16>.size, options: [])
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
            
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = sampleCount
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()
        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)

        
    }
    
    func convert (x: Float, y: Float)->(Float,Float){
        let newx = (Float(viewPortSize.x) / 512 * 2.0) * ( x / (Float(viewPortSize.x) / 2 ) - 1)
        let newy = -1 * ((Float(viewPortSize.y) / 512 * 2.0) * (y / (Float(viewPortSize.y) / 2 ) - 1))
        return (newx,newy)
    }
    
    func display(_ layer: CALayer) {
        //print("Display")
        self.render()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            points.append(convert(x:Float(position.x), y:Float(position.y)))
            print("Start: \(convert(x:Float(position.x), y:Float(position.y)))")
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            points.append(convert(x:Float(position.x), y:Float(position.y)))
            (vertexData,vertexIndex) = computeTriangles2(points: points, force: 0.02)
            for (index, val) in vertexData.enumerated() {
                pointsMem?.advanced(by: MemoryLayout<Float>.stride * (index + vertexCount)).storeBytes(of: val, as: Float.self)
            }
            
            for(index, val) in vertexIndex.enumerated() {
                indexMem?.advanced(by: MemoryLayout<UInt16>.stride * (index + indexCount)).storeBytes(of: val, as: UInt16.self)
            }
            vertexCount += vertexData.count
            indexCount += vertexIndex.count
            points = [points.last!]
        }
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            points.append(convert(x:Float(position.x), y:Float(position.y)))
            (vertexData,vertexIndex) = computeTriangles2(points: points, force: 0.02)
            
            
            
            for (index, val) in vertexData.enumerated() {
                pointsMem?.advanced(by: MemoryLayout<Float>.stride * (index + vertexCount)).storeBytes(of: val, as: Float.self)
            }
            
            for(index, val) in vertexIndex.enumerated() {
                indexMem?.advanced(by: MemoryLayout<UInt16>.stride * (index + indexCount)).storeBytes(of: val, as: UInt16.self)
            }
            vertexCount += vertexData.count
            indexCount += vertexIndex.count
            /*vertexCount = vertexData.count
            indexCount = vertexIndex.count
            vertexBuffer.contents().copyMemory(from: vertexData, byteCount: vertexCount * MemoryLayout<Float>.stride)
            indexBuffer.contents().copyMemory(from: vertexIndex, byteCount: indexCount * MemoryLayout<UInt16>.stride)*/
            
            points = []
            print("End: \(convert(x:Float(position.x), y:Float(position.y)))")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //metalLayer.frame = view.layer.frame
        if let window = view.window {
            //print("now")
            let scale = window.screen.nativeScale
            let layerSize = view.bounds.size
            view.contentScaleFactor = scale
            metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
            metalLayer.drawableSize = CGSize(width: layerSize.width, height: layerSize.height)
            viewPortSize.x = UInt32(layerSize.width)
            viewPortSize.y = UInt32(layerSize.height)
        }
        
        
    }
    


    
    func computeTriangles(ax: Float, ay: Float, bx: Float, by: Float, force: Float) -> [Float]{
        
        let norm = sqrtf((ay-by)*(ay-by) + ((ax-bx)*(ax-bx)))
        let vcx = (force * (ay - by)) / norm
        let vcy = ((-1 * force)*(ax - bx)) / norm
        let vccx = ((-1 * force)*(ay - by)) / norm
        let vccy = (force * (ax - bx)) / norm
        let cx = ax + vcx
        let cy = ay + vcy
        let dx = ax + vccx
        let dy = ay + vccy
        let ex = bx + vcx
        let ey = by + vcy
        let fx = bx + vccx
        let fy = by + vccy
         
        return [cx, cy, 0.0,
                ex, ey, 0.0,
                ax, ay, 0.0,
                ax, ay, 0.0,
                fx, fy, 0.0,
                dx, dy, 0.0,
                ex, ey, 0.0,
                ax, ay, 0.0,
                fx, fy, 0.0]
        
    }
    
    func computeTriangles2(points: [(Float, Float)], force: Float) -> ([Float],[UInt16]) {
        var triangleArr: [Float] = [points[0].0,points[0].1,0.0]
        var index: [UInt16] = []
        var ex: Float = 0
        var ey: Float = 0
        var fx: Float = 0
        var fy: Float = 0
        //print("length \(points.count)")
        var j: UInt16 = 0
        for i in 0..<(points.count - 1) {
            
            
            
            let ax = points[i].0
            let ay = points[i].1
            let bx = points[i+1].0
            let by = points[i+1].1
            let norm = sqrtf((ay-by)*(ay-by) + ((ax-bx)*(ax-bx)))
            let vcx = (force * (ay - by)) / norm
            let vcy = ((-1 * force)*(ax - bx)) / norm
            let vccx = ((-1 * force)*(ay - by)) / norm
            let vccy = (force * (ax - bx)) / norm
            let cx = ax + vcx
            let cy = ay + vcy
            let dx = ax + vccx
            let dy = ay + vccy
            
            ex = bx + vcx
            ey = by + vcy
            fx = bx + vccx
            fy = by + vccy
            triangleArr.append(contentsOf: [cx,cy,0.0,dx,dy,0.0,ex,ey,0.0,fx,fy,0.0,bx,by,0.0])
            let vc = UInt16(vertexCount / 3)
            index.append(contentsOf: [5*j+1 + vc,
                                           5*j+2 + vc,
                                           5*j + vc,
                                           5*j + vc,
                                           5*j+4 + vc,
                                           5*j+2 + vc,
                                           5*j+3 + vc,
                                           5*j + vc,
                                           5*j+4 + vc,
                                     5*j + vc,
                                     5*j+1 + vc,
                                        5*j+3 + vc])
            
            if (i > 0) {
                index.append(contentsOf: [5*j-2 + vc,
                                          5*j + vc,
                                          5*j+1 + vc,
                                          5*j-1 + vc,
                                          5*j + vc,
                                          5*j+2 + vc])
            }
            
            j = j+1
            
            
        }
        return (triangleArr,index)
    }
    
    func render(){
        let commandBuffer = commandQueue.makeCommandBuffer()!
        guard let drawable = metalLayer?.nextDrawable() else { return }
        
        let desc = MTLTextureDescriptor()
        desc.textureType = .type2DMultisample
        desc.width = Int(viewPortSize.x)
        desc.height = Int(viewPortSize.y)
        desc.sampleCount = sampleCount
        desc.pixelFormat = .bgra8Unorm
        let newTexture = self.device.makeTexture(descriptor: desc)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].texture = newTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
          red: 0.0,
          green: 104.0/255.0,
          blue: 55.0/255.0,
          alpha: 1.0)
        
        let renderEncoder = commandBuffer
          .makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewPortSize.x), height: Double(viewPortSize.y), znear: 0.0, zfar: 1.0))
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_uint2>.size, index: 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
     
        if(indexCount != 0){
            //print("Vertex Index: \(vertexIndex.count)")
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        //renderEncoder
           // .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count, instanceCount: 1)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        

    }

    @objc func gameloop(){
        autoreleasepool {
            //print("REnder")
            self.render()
        }
    }

}

