//
//  Canvas.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation

//I have no Idea if this thing will ever be usefulll

class Canvas {
    var brushes: [Brush]
    var currentBrush: Brush?
    var lines: [Line]
    var activeLine: Line?
    var pdf: Texture?
    
    init() {
        self.brushes = []
        self.lines = []
    }
    
    
}
