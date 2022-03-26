//
//  MetalViewController.swift
//  metalTest
//
//  Created by Tom Rudnick on 22.03.22.
//

import Foundation
import UIKit
import Metal
import simd
import MetalKit

protocol RendererDelegate {
    func render()
}

class MetalView: UIView {
    static let sampleCount = 4 //4x MSAA
    var metalLayer: CAMetalLayer!
    var delegate: RendererDelegate?
    var viewportSize: vector_uint2!
    var scale: CGFloat!
    var timer: CADisplayLink!
    let metalLayerDelegate = MetalLayerDelegate()
    public init(frame: CGRect, scale: CGFloat) {
        super.init(frame: frame)
        viewportSize = vector_uint2(x: UInt32(self.frame.width), y: UInt32(self.frame.height))
        self.scale = scale
        self.isOpaque = false
        metalLayer = CAMetalLayer()
        metalLayer.frame = self.frame
        
        metalLayer.delegate = metalLayerDelegate
        metalLayer.needsDisplayOnBoundsChange = true


        self.layer.addSublayer(metalLayer)
        
        timer = CADisplayLink(target: self, selector: #selector(drawLoop))
        timer.add(to: RunLoop.main, forMode: .default)
        metalLayerDelegate.metalView = self
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func drawLoop() {
        autoreleasepool {
            delegate?.render()
        }
    }
    
    func updateViewPortSize(size: CGSize, scale: CGFloat) {
        print(scale)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        metalLayer.drawableSize = CGSize(width: size.width * scale, height: size.height * scale)
        metalLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.contentScaleFactor = scale
        self.scale = scale
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
    }
    
}

//This Class is a way to fix the Problem that the app crashes if the delegate of the MetalLayer is set to self in MetalView....
//Therefore it is set to an instance of this class.
class MetalLayerDelegate: NSObject, CALayerDelegate {
    weak var metalView: MetalView?
    func display(_ layer: CALayer) {
        if let metalView = metalView {
            metalView.delegate?.render()
        }
    }
}

