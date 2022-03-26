//
//  MainViewController.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import UIKit
import PDFKit

class MainViewController: UIViewController {
    var metalView: MetalView!
    var renderer: Renderer!
    var canvas: Canvas!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var colorSwitch: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPDFView()
        canvas = Canvas()
        metalView = MetalView(frame: self.view.bounds, scale: view.window?.screen.nativeScale ?? 1.0)
        renderer = Renderer(metalView: metalView, canvas: canvas)
        metalView.delegate = renderer
        canvas.brushes = [Brush(color: SIMD4<Float>(x: 0.14, y: 0.58, z: 0.74, w: 1.0))]
        canvas.currentBrush = canvas.brushes[0]
        
        view.addSubview(metalView)
        self.view.bringSubviewToFront(clearButton)
        self.view.bringSubviewToFront(undoButton)
        self.view.bringSubviewToFront(colorSwitch)
        
        
        // PDF SETUP STUFF
        renderer.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        metalView.metalLayer.backgroundColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        metalView.metalLayer.isOpaque = false
        
    }
    
    func setupPDFView(){
        let pdfView = PDFView()
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        guard let path = Bundle.main.url(forResource: "example", withExtension: "pdf") else { return }
        
        if let document = PDFDocument(url: path) {
            print("Doc added")
            pdfView.document = document
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let window = view.window {
            let scale = window.screen.nativeScale
            let layerSize = view.bounds.size
            view.contentScaleFactor = scale
            print(self.view.bounds)
            metalView.frame = self.view.bounds
            metalView.updateViewPortSize(size: layerSize, scale: scale)
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
    
    
    @IBAction func clearPressed(_ sender: Any) {
        self.canvas.lines = []
    }
    
    @IBAction func undoPressed(_ sender: Any) {
        if !self.canvas.lines.isEmpty {
            self.canvas.lines.removeLast()
        }
    }
    
    @IBAction func colorChanged(_ sender: Any) {
        switch colorSwitch.selectedSegmentIndex {
        case 0:
            canvas.currentBrush?.color = SIMD4<Float>(x: 0.14, y: 0.58, z: 0.74, w: 1.0)
        case 1:
            canvas.currentBrush?.color = SIMD4<Float>(x: 0.68, y: 0.22, z: 0.156, w: 1.0)
        default:
            break
        }
        
    }
}
