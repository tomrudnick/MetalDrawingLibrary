//
//  Line.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import Metal
import UIKit
import simd

class Line {
    var vertexBuffer: MTLBuffer?
   // var indexBuffer: MTLBuffer?
    
    var indexCount = 0
    var vertexCount = 0
    
    var brush: Brush
    
    private var trianglesArr: [Float] = []
    private var indexArr: [UInt16] = []
    
    private var bezierGenerator: BezierGenerator
    
    var vertexPoints: [Vertex] = []
    
    init(brush: Brush) {
        self.brush = brush
        self.bezierGenerator = BezierGenerator()
        //vertexBuffer = Renderer.device.makeBuffer(length: 100 * 4096 * MemoryLayout<Vertex>.stride, options: [])
        //indexBuffer = Renderer.device.makeBuffer(length: 100 * 4096 * MemoryLayout<Float>.stride, options: [])
    }
    
   

    
    func addPoint(_ point: CGPoint) {
        let points = bezierGenerator.pushPoint(point)
        if (points.isEmpty) { return }
        for point in points {
            print("X: \(point.x) Y: \(point.y)")
            vertexPoints.append(Vertex(position: SIMD3<Float>(x: Float(point.x), y: Float(point.y), z: 0.0), force: 10.0))
        }
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertexPoints, length: MemoryLayout<Vertex>.stride * vertexPoints.count, options: [])
        
        
        /*computeTriangles(points: points, force: 0.02)
        for (index, val) in trianglesArr[vertexCount..<trianglesArr.count].enumerated() {
            print("Added: \(val)")
            vertexBuffer?.contents().advanced(by: MemoryLayout<Float>.stride * (index + vertexCount)).storeBytes(of: val, as: Float.self)
        }
        
        for(index, val) in indexArr[indexCount..<indexArr.count].enumerated() {
            indexBuffer?.contents().advanced(by: MemoryLayout<UInt16>.stride * (index + indexCount)).storeBytes(of: val, as: UInt16.self)
        }
        vertexCount = trianglesArr.count
        indexCount = indexArr.count*/
        
        /*for (index, val) in points.enumerated() {
            let vertex = Vertex(position: SIMD3<Float>(x: Float(val.x), y: Float(val.y), z: 0.0), force: 10.0)
            vertexBuffer?.contents().advanced(by: MemoryLayout<Vertex>.stride * (index + vertexCount)).storeBytes(of: vertex, as: Vertex.self)
            print("Index: \(index + vertexCount) Added X: \(val.x) Y: \(val.y) Z: \(0.0) VM: \(MemoryLayout<Vertex>.stride) FM: \(MemoryLayout<Float>.stride) \(MemoryLayout<SIMD2<Float>>.stride)")
        }
        
        vertexCount += points.count*/
        
        /*for (_,val) in points.enumerated() {
            print("Added X: \(val.x) Y: \(val.y) Z: \(0.0)")
        }*/
        
    }
    
    func addLastPoint(_ point: CGPoint) {
        addPoint(point)
        bezierGenerator.finish()
        trianglesArr = []
    }
    
    
    func computeTriangles(points: [CGPoint], force: Float) {
        trianglesArr.append(contentsOf: [Float(points[0].x),Float(points[0].y),0.0])
        var ex: Float = 0
        var ey: Float = 0
        var fx: Float = 0
        var fy: Float = 0
        //print("length \(points.count)")
        for i in 0..<(points.count - 1) {
            let ax = Float(points[i].x)
            let ay = Float(points[i].y)
            let bx = Float(points[i+1].x)
            let by = Float(points[i+1].y)
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
            trianglesArr.append(contentsOf: [cx,cy,0.0,dx,dy,0.0,ex,ey,0.0,fx,fy,0.0,bx,by,0.0])
            let vc = UInt16(vertexCount / 3)
            let tmp = 5 * UInt16(i) + vc
            indexArr.append(contentsOf: [
                                        tmp + 1,
                                        tmp + 2,
                                        tmp,
                                        tmp,
                                        tmp + 4,
                                        tmp + 2,
                                        tmp + 3,
                                        tmp,
                                        tmp + 4,
                                        tmp,
                                        tmp + 1,
                                        tmp + 3
                                     ])
            
            if (i > 0 || trianglesArr.count > 18) {
                indexArr.append(contentsOf: [
                                          tmp - 2,
                                          tmp,
                                          tmp + 1,
                                          tmp - 1,
                                          tmp,
                                          tmp + 2
                                         ])
            }
        }
    }
    
}