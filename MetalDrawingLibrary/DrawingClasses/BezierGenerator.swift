//
//  BezierGenerator.swift
//  MaLiang
//
//  Created by Harley.xk on 2017/11/10.
//

import UIKit

class BezierGenerator {

    enum Style {
        case linear
        case quadratic  // this is the only style currently supported
        case cubic
    }
        
    init() {
    }
    
    init(beginPoint: CGPoint) {
        begin(with: beginPoint)
    }
    
    func begin(with point: CGPoint) {
        step = 0
        points.removeAll()
        points.append(point)
    }
    
    func pushPoint(_ point: CGPoint) -> [CGPoint] {
        if point == points.last {
            return []
        }
        points.append(point)
        if points.count < style.pointCount {
            return []
        }
        step += 1
        let result = genericPathPoints()
        return result
    }
    
    func finish() {
        step = 0
        points.removeAll()
    }
    
    var points: [CGPoint] = []
    var style: Style = .quadratic
    
    private var step = 0
    private func genericPathPoints() -> [CGPoint] {
        
        var begin: CGPoint
        var control: CGPoint
        let end = CGPoint.middle(p1: points[step], p2: points[step + 1])

        var vertices: [CGPoint] = []
        if step == 1 {
            begin = points[0]
            let middle1 = CGPoint.middle(p1: points[0], p2: points[1])
            control = CGPoint.middle(p1: middle1, p2: points[1])
        } else {
            begin = CGPoint.middle(p1: points[step - 1], p2: points[step])
            control = points[step]
        }
        /// segements are based on distance about start and end point
        let dis = begin.distance(to: end)
        let segements = max(Int(dis / 5), 2)
        var f : CGFloat
        for i in 0 ..< segements {
            let t = CGFloat(i) / CGFloat(segements)
            let x = pow(1 - t, 2) * begin.x + 2.0 * (1 - t) * t * control.x + t * t * end.x
            let y = pow(1 - t, 2) * begin.y + 2.0 * (1 - t) * t * control.y + t * t * end.y
            vertices.append(CGPoint(x: x, y: y))
        }
        vertices.append(end)
        return vertices
    }
    private func genericPathPointscubic() -> [CGPoint] {
    
    var begin: CGPoint
    let end = CGPoint.middle(p1: points[step], p2: points[step + 1])

    var vertices: [CGPoint] = []
    /*if step == 1 {
        begin = points[0]
        //let middle1 = CGPoint.middle(p1: points[0], p2: points[1])
        //control = CGPoint.middle(p1: middle1, p2: points[1])
    } else {
        begin = CGPoint.middle(p1: points[step - 1], p2: points[step])
        //control = points[step]
    }*/
    begin = CGPoint.middle(p1: points[step - 1], p2: points[step])

    let before = points[step-1]
    let after = points[step]
        let v1 = CGVector(dx: (before.x-end.x), dy: (before.y-end.y))
        let v2 = CGVector(dx: (after.x-begin.x), dy: (after.y-begin.y))
    //let vx = (end.x-begin.x)/3
    //let vy = (end.y-begin.y)/3
        let d1 = CGPoint(x: begin.x-v1.dx, y: begin.y-v1.dy)
        let d2 = CGPoint(x: begin.x-v2.dx, y: begin.y-v2.dy)
    
    /// segements are based on distance about start and end point
    let dis = begin.distance(to: end)
    let segements = max(Int(dis * 5), 2)

    for i in 0 ..< segements {
        let t = CGFloat(i) / CGFloat(segements)
        let x = pow(1 - t, 3) * begin.x + 3 * t * pow(1 - t, 2) * d1.x + 3 * pow(t, 2) * (1 - t) * d2.x + pow(t, 3) * end.x
        let y = pow(1 - t, 3) * begin.y + 3 * t * pow(1 - t, 2) * d1.y + 3 * pow(t, 2) * (1 - t) * d2.y + pow(t, 3) * end.y
        vertices.append(CGPoint(x: x, y: y))
    }
    vertices.append(end)
    return vertices
}
}



extension BezierGenerator.Style {
    var pointCount: Int {
        switch self {
        case .quadratic: return 3
        case .cubic: return 4
        default: return Int.max
        }
    }
}

