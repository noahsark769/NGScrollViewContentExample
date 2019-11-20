//
//  Renderer.swift
//  MetalBoilerplate Shared
//
//  Created by Noah Gilmore on 11/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

class Renderer: NSObject, MTKViewDelegate {

    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var dynamicUniformBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var uniformBufferOffset = 0

    var uniformBufferIndex = 0

    var uniforms: UnsafeMutablePointer<Uniforms>

    var projectionMatrix: matrix_float4x4 = matrix_float4x4()

    private let vertices: [Vertex]
    private let indices: [UInt16]
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer

    var scale: Float = 1
    var contentOffsetX: Float = 0
    var contentOffsetY: Float = 0
    var contentWidth: Float = 0
    var contentHeight: Float = 0
    private var viewSize: CGSize = .zero
    var contentBounds: CGRect = .zero

    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue

        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight

        guard let buffer = self.device.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else { return nil }
        dynamicUniformBuffer = buffer

        self.dynamicUniformBuffer.label = "UniformBuffer"

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)

        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1

        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: device,
                                                                       metalKitView: metalKitView)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }

        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state

        var vertices: [Vertex] = []
        var indices: [UInt16] = []
        let squareSize: Float = 40
        let spacing: Float = 20
        let offset: Float = 5
        for y in 0..<20 {
            for x in 0..<20 {
                let currentVertexCount = UInt16(vertices.count)

                let xCoordinate = (squareSize + spacing) * Float(x)
                let yCoordinate = (squareSize + spacing) * Float(y)
                vertices.append(Vertex(position: SIMD3<Float>(xCoordinate - offset, yCoordinate - offset, 0)))
                vertices.append(Vertex(position: SIMD3<Float>(xCoordinate + squareSize + offset, yCoordinate - offset, 0)))
                vertices.append(Vertex(position: SIMD3<Float>(xCoordinate - offset, yCoordinate + squareSize + offset, 0)))
                vertices.append(Vertex(position: SIMD3<Float>(xCoordinate + squareSize + offset, yCoordinate + squareSize + offset, 0)))

                indices.append(currentVertexCount)
                indices.append(currentVertexCount + 1)
                indices.append(currentVertexCount + 2)
                indices.append(currentVertexCount + 1)
                indices.append(currentVertexCount + 3)
                indices.append(currentVertexCount + 2)
            }
        }
//        vertices.append(Vertex(position: SIMD3<Float>(0, 0, 0)))
//        vertices.append(Vertex(position: SIMD3<Float>(1, 0, 0)))
//        vertices.append(Vertex(position: SIMD3<Float>(0, 1, 0)))
//        vertices.append(Vertex(position: SIMD3<Float>(1, 1, 0)))
//        indices.append(0)
//        indices.append(1)
//        indices.append(2)
//        indices.append(1)
//        indices.append(3)
//        indices.append(2)
        guard let vertexBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(mutating: vertices), length: MemoryLayout<Vertex>.size * vertices.count, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate vertex buffer")
        }
        self.vertexBuffer = vertexBuffer
        self.vertices = vertices // we need to retain this since we're passing in a raw unsafe pointer
        guard let indexBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(mutating: indices), length: MemoryLayout<UInt16>.size * indices.count, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate index buffer")
        }
        self.indexBuffer = indexBuffer
        self.indices = indices

        super.init()

    }

    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object

        let library = device.makeDefaultLibrary()

        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering

        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight

        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }

    private func updateGameState() {
        /// Update any game state before rendering

//        let squareSize: Float = 40
//        let spacing: Float = 20
    //        let offset: Float = 5

//        let worldWidth: Float = squareSize * 8 + spacing * 7
//        let worldHeight: Float = squareSize * 8 + spacing * 7
        let aspect = Float(self.contentWidth) / Float(self.contentHeight)

//        if self.contentWidth > self.contentHeight {
//            // landscape mode
//            // Does not work, need to account for content offset
//            projectionMatrix = matrix_ortho_projection(left: self.contentOffsetX, right: self.contentWidth * aspect, top: self.contentOffsetY, bottom: self.contentHeight, near: 1, far: -1)
//        } else {
            // portrait mode
        let effectiveRect = self.contentBounds.applying(CGAffineTransform(scaleX: CGFloat(1 / self.scale), y: CGFloat(1 / self.scale)))
        projectionMatrix = matrix_ortho_projection(
//            left: self.contentOffsetX,
//            right: //max(
//                contentOffsetX + self.contentWidth,
//                Float(self.viewSize.width)
//            ),
//            top: self.contentOffsetY,
//            bottom: //max(
//                (self.contentOffsetY + self.contentHeight) * 1 / aspect,
//                Float(self.viewSize.height)
//            ),
//            bottom: (),
            left: Float(effectiveRect.origin.x),
            right: Float(effectiveRect.origin.x + effectiveRect.width),
            top: Float(effectiveRect.origin.y),
            bottom: Float(effectiveRect.origin.y + effectiveRect.height),
            near: 1,
            far: -1
        )
//        }

        uniforms[0].projectionMatrix = projectionMatrix
        uniforms[0].modelViewMatrix = matrix4x4_identity()
//            * matrix4x4_translation(self.contentOffsetX, self.contentOffsetY, 0)
//            * matrix4x4_scale(x: self.scale, y: self.scale)
    }

    func draw(in view: MTKView) {
        /// Per frame updates hare

        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

        if let commandBuffer = commandQueue.makeCommandBuffer() {

            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }

            self.updateDynamicBufferState()

            self.updateGameState()

            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor

            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {

                /// Final pass rendering code here
                renderEncoder.label = "Primary Render Encoder"

                renderEncoder.pushDebugGroup("Draw Box")

                renderEncoder.setCullMode(.back) // ?
                renderEncoder.setFrontFacing(.clockwise)

                renderEncoder.setRenderPipelineState(pipelineState)

                renderEncoder.setDepthStencilState(depthState)

                renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: 1)
                renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: 0)
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: self.indices.count, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)

                renderEncoder.popDebugGroup()

                renderEncoder.endEncoding()

                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }

            commandBuffer.commit()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

//        let squareSize: Float = 40
//        let spacing: Float = 20
//    //        let offset: Float = 5
//
//        let worldWidth: Float = squareSize * 8 + spacing * 7
//        let worldHeight: Float = squareSize * 8 + spacing * 7
//        let aspect = Float(size.width) / Float(size.height)
//
//        if size.width > size.height {
//            // landscape mode
//            projectionMatrix = matrix_ortho_projection(left: 0, right: worldWidth * aspect, top: 0, bottom: worldHeight, near: 1, far: -1)
//        } else {
//            // portrait mode
//            projectionMatrix = matrix_ortho_projection(left: 0, right: worldWidth, top: 0, bottom: worldHeight * 1 / aspect, near: 1, far: -1)
//        }

//        projectionMatrix = matrix_ortho_projection(left: 0, right: 2, top: 0, bottom: 2, near: 1, far: -1)
        self.viewSize = CGSize(width: size.width / view.contentScaleFactor, height: size.height / view.contentScaleFactor)
        view.setNeedsDisplay()
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func matrix_ortho_projection(left: Float, right: Float, top: Float, bottom: Float, near: Float, far: Float) -> matrix_float4x4 {
    let xs = 2.0 / (right - left)
    let ys = 2.0 / (top - bottom)
    let zs = -2.0 / (far - near)
    let tx = -((right + left) / (right - left))
    let ty = -((top + bottom) / (top - bottom))
    let tz = -((far + near) / (far - near))

    return matrix_float4x4.init(
        rows: [
            vector_float4(xs,  0,  0, tx),
            vector_float4( 0, ys,  0, ty),
            vector_float4( 0,  0, zs, tz),
            vector_float4( 0,  0,  0,  1)
        ]
    )
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

func matrix4x4_scale(x: Float, y: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(x, 0, 0, 0),
                                         vector_float4(0, y, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(0, 0, 0, 1)))
}

func matrix4x4_identity() -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(0, 0, 0, 1)))
}
