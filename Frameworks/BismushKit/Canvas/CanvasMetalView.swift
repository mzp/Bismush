//
//  MetalView.swift
//  Bismush
//
//  Created by mzp on 3/15/22.
//

import Metal
import MetalKit

struct Vertex {
    var position: SIMD2<Float>
    var textureCoordinate: SIMD2<Float>
}

let vertices: [Vertex] = [
    Vertex(position: SIMD2(500, -500), textureCoordinate: SIMD2(1.0, 1.0)),
    Vertex(position: SIMD2(-500, -500), textureCoordinate: SIMD2(0.0, 1.0)),
    Vertex(position: SIMD2(-500, 500), textureCoordinate: SIMD2(0.0, 0.0)),

    Vertex(position: SIMD2(500, -500), textureCoordinate: SIMD2(1.0, 1.0)),
    Vertex(position: SIMD2(-500, 500), textureCoordinate: SIMD2(0.0, 0.0)),
    Vertex(position: SIMD2(500, 500), textureCoordinate: SIMD2(1.0, 0.0)),
]

public class CanvasMetalView: MTKView {
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let texture: MTLTexture
    private var viewPortSize = SIMD2<UInt32>(0, 0)

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Device loading error")
        }

        BismushLogger.metal.info("Use \(device.name)")
        commandQueue = Self.makeCommandQueue(device: device)
        renderPipelineState = Self.makeRenderPipelineState(device: device)
        vertexBuffer = Self.makeVertexBuffer(device: device, bytes: vertices,
                                             length: MemoryLayout<Vertex>.stride * vertices.count)
        texture = Self.makeTexture(device: device)

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
        device.makeBuffer(bytes: bytes, length: length, options: [.storageModeShared])!
    }

    private static func makeTexture(device: MTLDevice) -> MTLTexture {
        let loader = MTKTextureLoader(device: device)

        let bundle = Bundle(for: Self.self)
        let url = bundle.url(forResource: "yosemite", withExtension: "png")!
        // swiftlint:disable:next force_try
        return try! loader.newTexture(URL: url)
    }
}

extension CanvasMetalView: MTKViewDelegate {
    public func mtkView(_: MTKView, drawableSizeWillChange size: CGSize) {
        viewPortSize.x = UInt32(size.width)
        viewPortSize.y = UInt32(size.height)
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        guard let buffer = commandQueue.makeCommandBuffer() else {
            return
        }
        buffer.label = "Frame"
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        defer {
            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(viewPortSize.x),
            height: Double(viewPortSize.y),
            znear: -1,
            zfar: 1
        )
        encoder.label = "Render"
        encoder.setViewport(viewPort)
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&viewPortSize, length: MemoryLayout<SIMD2<UInt>>.size, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}
