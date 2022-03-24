//
//  MainViewController.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import UIKit


class MainViewController: UIViewController {
    var metalView: MetalView!
    var renderer: Renderer!
    var canvas: Canvas!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvas = Canvas()
        metalView = MetalView(frame: self.view.bounds)
        renderer = Renderer(metalView: metalView, canvas: canvas)
        metalView.delegate = renderer
        canvas.brushes = [Brush()]
        canvas.currentBrush = canvas.brushes[0]
        print("Hello")
        view.addSubview(metalView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let window = view.window {
            let scale = window.screen.nativeScale
            let layerSize = view.bounds.size
            view.contentScaleFactor = scale
            print(self.view.bounds)
            metalView.frame = self.view.bounds
            metalView.updateViewPortSize(size: layerSize)
            renderer.recreateTexture()
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let brush = canvas.currentBrush {
            let position = touch.location(in: view)
            canvas.activeLine = Line(brush: brush)
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            //print(convert(x: position.x, y: position.y))
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y))
            if let line = canvas.activeLine {
                canvas.lines.append(line)
                canvas.activeLine = nil
            }
        }
    }
    
    
    
    func convert (x: CGFloat, y: CGFloat)-> CGPoint{
        let newx = (CGFloat(metalView.viewportSize.x) / 512 * 2.0) * ( x / (CGFloat(metalView.viewportSize.x) / 2 ) - 1)
        let newy = -1 * (CGFloat(metalView.viewportSize.y) / 512 * 2.0) * (y / (CGFloat(metalView.viewportSize.y) / 2 ) - 1)
        return CGPoint(x: newx, y: newy)
    }
}
