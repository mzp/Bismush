//
//  MetalView.swift
//  Bismush
//
//  Created by mzp on 3/15/22.
//

import Metal
import MetalKit

struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

let vertices: [Vertex] = [
    Vertex(position: SIMD3(0, 1, 0), color: SIMD4(1, 0, 0, 1)),
    Vertex(position: SIMD3(-1, -1, 0), color: SIMD4(0, 1, 0, 1)),
    Vertex(position: SIMD3(1, -1, 0), color: SIMD4(0, 0, 1, 1)),
]

public class CanvasMetalView: MTKView {
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Device loading error")
        }
        BismushLogger.metal.info("Use \(device.name)")
        commandQueue = Self.makeCommandQueue(device: device)
        renderPipelineState = Self.makeRenderPipelineState(device: device)
        vertexBuffer = Self.makeVertexBuffer(device: device, bytes: vertices,
                                             length: MemoryLayout<Vertex>.stride * vertices.count)

        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())

        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0.1, green: 0.57, blue: 0.25, alpha: 1)
        delegate = self
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeCommandQueue(device: MTLDevice) -> MTLCommandQueue {
        device.makeCommandQueue()!
    }

    private static func makeRenderPipelineState(device: MTLDevice) -> MTLRenderPipelineState {
        let bundle = Bundle(for: Self.self)
        // swiftlint:disable:next force_try
        let library = try! device.makeDefaultLibrary(bundle: bundle)
        BismushLogger.metal.info("Use library: \(library.description)")
        guard let vertexFunction = library.makeFunction(name: "canvas_vertex") else {
            fatalError("not found")
        }
        guard let fragmentFunction = library.makeFunction(name: "canvas_fragment") else {
            fatalError("not found")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        // swiftlint:disable:next force_try
        return try! device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeVertexBuffer(device: MTLDevice, bytes: UnsafeRawPointer, length: Int) -> MTLBuffer {
        device.makeBuffer(bytes: bytes, length: length, options: [])!
    }
}

extension CanvasMetalView: MTKViewDelegate {
    public func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        guard let buffer = commandQueue.makeCommandBuffer() else {
            return
        }
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        defer {
            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }

        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}
