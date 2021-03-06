//
//  MainViewController.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import UIKit
import PDFKit
import Alloy

class MainViewController: UIViewController {
    var metalView: MetalView!
    var renderer: Renderer!
    var canvas: Canvas!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var colorSwitch: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupPDFView() //Comment out if you dont want to use the PDF viewer
        
        metalView = MetalView(frame: self.view.bounds, scale: view.window?.screen.nativeScale ?? 1.0)
        canvas = Canvas(metalView: metalView)
        renderer = Renderer(metalView: metalView, canvas: canvas)
        metalView.delegate = renderer
        canvas.brushes = [Brush(color: SIMD4<Float>(x: 0.14, y: 0.58, z: 0.74, w: 1.0))]
        canvas.currentBrush = canvas.brushes[0]
        setupPDFView2()
        
        view.addSubview(metalView) //COMMENT OUT if you only want to test the PDF View Functionality
        self.view.bringSubviewToFront(clearButton)
        self.view.bringSubviewToFront(undoButton)
        self.view.bringSubviewToFront(colorSwitch)
        addZoom()
        
        // PDF SETUP STUFF //This will make the MetalLayer transparent so you can see the PDF VIEW
        //renderer.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        //metalView.metalLayer.backgroundColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        //metalView.metalLayer.isOpaque = false
        
    }
    
    func setupPDFView2(){
        guard let path = Bundle.main.url(forResource: "pdf2", withExtension: "pdf") else { return }
        canvas.pdf = Texture(url: path, midPosition: CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2), canvas: canvas)
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
    
    func addZoom(){
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        
        view.addGestureRecognizer(pinch)
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
            if(touch.type != UITouch.TouchType.pencil){
                return
            }
            let position = touch.preciseLocation(in: view)
            canvas.activeLine = Line(brush: brush)
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y), touch.force/touch.maximumPossibleForce)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if(touch.type != UITouch.TouchType.pencil){
                return
            }
            let position = touch.preciseLocation(in: view)
            let force = touch.force / touch.maximumPossibleForce
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y), force)
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if(touch.type != UITouch.TouchType.pencil){
                return
            }
            let position = touch.preciseLocation(in: view)
            let force = touch.force
            canvas.activeLine?.addPoint(convert(x: position.x, y: position.y), force/touch.maximumPossibleForce)
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
    
    var deltaScale : Float = 0.0
    @objc func didPinch(_ sender: UIPinchGestureRecognizer){
        if(sender.state == .began){
            var location = sender.location(in: view)
            location = convert(x: location.x, y: location.y)
            canvas.zoomPoint = SIMD2<Float>(Float(location.x),Float(location.y))
            print("zoomPoint: \(canvas.zoomPoint)")
            deltaScale = canvas.zoom - 1
        }
        if (sender.state == .changed){
            let scale = Float(sender.scale)
            var zoom = scale + deltaScale
            if(scale<1){
                zoom = zoom - 1 + scale
            }
            if (zoom > 5){
                zoom = 5
            }else if(zoom<0.2){
                zoom = 0.2
            }
            canvas.zoom = zoom
        }
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
