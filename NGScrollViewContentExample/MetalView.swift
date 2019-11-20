//
//  MetalView.swift
//  NGScrollViewContentExample
//
//  Created by Noah Gilmore on 11/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import MetalKit

final class MetalView: MTKView {
    var renderer: Renderer!

    var scale: Float {
        get { return renderer.scale }
        set {
            renderer.scale = newValue
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
            renderer.contentBounds = self.contentBounds
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
//        self.presentsWithTransaction = true
//        self.isPaused = true
        self.enableSetNeedsDisplay = true

        guard let newRenderer = Renderer(metalKitView: self) else {
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
