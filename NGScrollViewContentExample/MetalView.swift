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

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        self.device = defaultDevice
        self.clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 0)
        self.isOpaque = false
        self.isUserInteractionEnabled = false
//        self.presentsWithTransaction = true

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
