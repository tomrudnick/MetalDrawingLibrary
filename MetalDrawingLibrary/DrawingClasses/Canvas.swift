//
//  Canvas.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import CoreGraphics

//I have no Idea if this thing will ever be usefulll

class Canvas {
    var brushes: [Brush]
    var currentBrush: Brush?
    var lines: [Line]
    var activeLine: Line?
    var pdf: Texture?
    var zoom: Float = 1.0
    weak var metalView: MetalView!
    var zoomPoint: SIMD2<Float> = SIMD2<Float>(0.0,0.0)
    
    init(metalView: MetalView) {
        self.metalView = metalView
        self.brushes = []
        self.lines = []
    }
    
    
}
