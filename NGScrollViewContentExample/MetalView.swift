//
//  MetalView.swift
//  NGScrollViewContentExample
//
//  Created by Noah Gilmore on 11/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import MetalKit

class CustomMetalLayer: CAMetalLayer {
    let renderer : Renderer
    var scaleAnimationsEnabled: Bool = true
    var animationTimingFunction: CAMediaTimingFunction?
    var animationDuration: CFTimeInterval = 0

    @NSManaged var scale: Float
    @NSManaged var contentWidth: Float
    @NSManaged var contentHeight: Float
    @NSManaged var contentOffsetX: Float
    @NSManaged var contentOffsetY: Float

    override init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.renderer = Renderer(device: device, sampleCount: 1, colorPixelFormat: .bgra8Unorm)!
        super.init()
        self.device = device
        self.fillMode = .backwards
    }

    override init(layer: Any) {
        guard let layer = layer as? CustomMetalLayer else {
            fatalError("Something's up with the layer, dude")
        }
        self.renderer = layer.renderer
        self.scaleAnimationsEnabled = layer.scaleAnimationsEnabled

        super.init(layer: layer)
        self.fillMode = layer.fillMode
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func display() {
        let effectiveLayer: CustomMetalLayer
        if self.scaleAnimationsEnabled {
            guard let layer = self.presentation() else {
                return
            }
            effectiveLayer = layer
        } else {
            effectiveLayer = self
        }
        renderer.scale = effectiveLayer.scale
        renderer.contentHeight = effectiveLayer.contentHeight
        renderer.contentWidth = effectiveLayer.contentWidth
        renderer.contentOffsetX = effectiveLayer.contentOffsetX
        renderer.contentOffsetY = effectiveLayer.contentOffsetY

        super.display()
    }

    static let customAnimatableKeys = [
        "scale",
        "contentWidth",
        "contentHeight",
        "contentOffsetX",
        "contentOffsetY"
    ]

    override class func needsDisplay(forKey key: String) -> Bool {
        if Self.customAnimatableKeys.contains(key) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func action(forKey event: String) -> CAAction? {
        guard self.scaleAnimationsEnabled else {
            return nil
        }

        guard let effectiveLayer = self.presentation() else {
            return super.action(forKey: event)
        }

        if Self.customAnimatableKeys.contains(event) {
            let animation = CABasicAnimation(keyPath: event)
//            if (effectiveLayer.animationKeys() ?? []).contains(event) {
//                print("Might be a duplicate action!!")
//                return super.action(forKey: event)
//            }
            animation.fromValue = effectiveLayer.value(forKey: event) // ?
            animation.duration = self.animationDuration
            animation.timingFunction = self.animationTimingFunction
            return animation
        }
        return super.action(forKey: event)
    }
}

// Thanks to https://stackoverflow.com/questions/45375548/resizing-mtkview-scales-old-content-before-redraw
// for the recipe behind this, although I had to add presentsWithTransaction and the wait to make it glitch-free
class MetalLayerView: UIView {
    var scale: Float {
        get { return self.metalLayer.scale }
        set {
            self.metalLayer.scale = newValue
        }
    }

    var animationsEnabled: Bool {
        get {
            return self.metalLayer.scaleAnimationsEnabled
        }
        set {
            self.metalLayer.scaleAnimationsEnabled = newValue
        }
    }

    var contentBounds: CGRect = .zero {
        didSet {
            self.metalLayer.contentOffsetX = Float(self.contentBounds.origin.x)
            self.metalLayer.contentOffsetY = Float(self.contentBounds.origin.y)
            self.metalLayer.contentWidth = Float(self.contentBounds.size.width)
            self.metalLayer.contentHeight = Float(self.contentBounds.size.height)
        }
    }

    var metalLayer: CustomMetalLayer {
        return self.layer as! CustomMetalLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        guard let metalLayer = self.layer as? CAMetalLayer else {
            fatalError("somethin wrong with da layer mate")
        }
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.delegate = self
//        metalLayer.allowsNextDrawableTimeout = false
//        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
    }

    override class var layerClass: AnyClass {
        return CustomMetalLayer.self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    func makeBackingLayer() -> CALayer {
//        metalLayer = CAMetalLayer()
//        metalLayer.pixelFormat = .bgra8Unorm
//        metalLayer.device = renderer.device
//        metalLayer.delegate = self
//
//        // If you're using the strategy of .topLeft placement and not presenting with transaction
//        // to just make the glitches less visible instead of eliminating them, it can help to make
//        // the background color the same as the background of your app, so the glitch artifacts
//        // (solid color bands at the edge of the window) are less visible.
////        metalLayer.backgroundColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
//
//        metalLayer.allowsNextDrawableTimeout = false
//
//        // these properties are crucial to resizing working
//        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
//        metalLayer.needsDisplayOnBoundsChange = true
//        metalLayer.presentsWithTransaction = true
//
//        return metalLayer
//    }

//    override func setFrameSize(_ newSize: NSSize) {
//        super.setFrameSize(newSize)
//        renderer.viewportSize.x = UInt32(newSize.width)
//        renderer.viewportSize.y = UInt32(newSize.height)
//        // the conversion below is necessary for high DPI drawing
//        metalLayer.drawableSize = convertToBacking(newSize)
//        self.viewDidChangeBackingProperties()
//    }

    override func display(_ layer: CALayer) {
        guard let metalLayer = self.layer as? CustomMetalLayer else {
            fatalError("somethin wrong with da layer mate")
        }

        let drawable = metalLayer.nextDrawable()!

        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        if metalLayer.scaleAnimationsEnabled {
            print("Animating render frame with scale: \(metalLayer.renderer.scale), contentOffset: \(metalLayer.renderer.contentOffsetX), \(metalLayer.renderer.contentOffsetY)")
        }

        metalLayer.renderer.draw(
            passDescriptor: passDescriptor,
            drawable: drawable
        )
    }
}


final class MetalView: MTKView {
    var renderer: Renderer!

    var scale: Float {
        get { return renderer.scale }
        set {
            renderer.scale = newValue
//            print("New scale: \(newValue)")
            self.setNeedsDisplay()
        }
    }

    var contentOffset: CGPoint = .zero {
        didSet {
            renderer.contentOffsetX = Float(self.contentOffset.x)
            renderer.contentOffsetY = Float(self.contentOffset.y)
            self.setNeedsDisplay()
        }
    }

    var contentSize: CGSize = .zero {
        didSet {
            renderer.contentWidth = Float(self.contentSize.width)
            renderer.contentHeight = Float(self.contentSize.height)
            self.setNeedsDisplay()
        }
    }

    var contentBounds: CGRect = .zero {
        didSet {
            self.renderer.contentOffsetX = Float(self.contentBounds.origin.x)
            self.renderer.contentOffsetY = Float(self.contentBounds.origin.y)
            self.renderer.contentWidth = Float(self.contentBounds.size.width)
            self.renderer.contentHeight = Float(self.contentBounds.size.height)
//            print("""
//                New bounds:
//                x: \(self.contentBounds.x) - \(self.renderer.contentOffsetX)
//                y: \(self.contentBounds.y) - \(self.renderer.contentOffsetY)
//                width: \(self.contentBounds.width) - \(self.renderer.contentWidth)
//                height: \(self.contentBounds.height) - \(self.renderer.contentHeight)
//            """)
//            print("""
//                x: \(self.renderer.contentOffsetX)
//            """)
            self.setNeedsDisplay()
        }
    }

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        self.device = defaultDevice
        self.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.isOpaque = false
        self.isUserInteractionEnabled = false
        self.presentsWithTransaction = true
//        self.isPaused = true
        self.enableSetNeedsDisplay = true

//        self.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        self.sampleCount = 1

        guard let newRenderer = Renderer(device: self.device!, sampleCount: self.sampleCount, colorPixelFormat: self.colorPixelFormat) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(self, drawableSizeWillChange: self.drawableSize)

        self.delegate = renderer
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
