//
//  CanvasLayerStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/31/22.
//

import Metal
import simd

protocol CanvasContext {
    var device: GPUDevice { get }
    var modelViewMatrix: Transform2D<WorldCoordinate, CanvasPixelCoordinate> { get }
}

public class ArtboardLayerStore {
    struct Context {
        var encoder: MTLRenderCommandEncoder
        var projection: Transform2D<ViewPortCoordinate, CanvasPixelCoordinate>
    }

    struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }

    public var canvasLayer: CanvasLayer
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
    let pixelFormat: MTLPixelFormat = .rgba8Unorm

    private let context: CanvasContext
    private var dirty = true
    private let buffer: MTLBuffer
    private let renderPipelineState: MTLRenderPipelineState

    var needsNewTexture = false

    init(canvasLayer: CanvasLayer, context: CanvasContext) {
        self.canvasLayer = canvasLayer
        self.context = context

        switch canvasLayer.layerType {
        case .empty:
            let description = MTLTextureDescriptor()
            description.width = Int(canvasLayer.size.width)
            description.height = Int(canvasLayer.size.height)
            description.pixelFormat = pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D

            texture = context.device.metalDevice.makeTexture(descriptor: description)!
        case let .builtin(name: name):
            texture = context.device.resource.bultinTexture(name: name)
        }

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false
        )

        if context.device.capability.msaa {
            desc.textureType = .type2DMultisample
            desc.sampleCount = 4
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            msaaTexture = context.device.metalDevice.makeTexture(descriptor: desc)!
        } else {
            msaaTexture = nil
        }

        buffer = context.device.metalDevice.makeBuffer(length: MemoryLayout<Vertex>.size * 6)!

        let descriptor = Self.renderPipelineDescriptor
        descriptor.vertexFunction = context.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = context.device.resource.function(.layerFragment)
        renderPipelineState = try! context.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
    }

    var device: GPUDevice { context.device }

    public var visible: Bool {
        get {
            canvasLayer.visible
        }
        set {
            canvasLayer.visible = newValue
        }
    }

    // MARK: - Transform

    var transform: Transform2D<LayerPixelCoordinate, CanvasPixelCoordinate> {
        .identity()
    }

    var renderTransform: Transform2D<LayerCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: -1, y: -1) *
                Transform2D.scale(x: Float(1 / canvasLayer.size.width * 2), y: Float(1 / canvasLayer.size.height * 2)))
    }

    func createNewTexture(commandBuffer: MTLCommandBuffer) {
        if let encoder = commandBuffer.makeBlitCommandEncoder() {
            let description = MTLTextureDescriptor()
            description.width = Int(canvasLayer.size.width)
            description.height = Int(canvasLayer.size.height)
            description.pixelFormat = pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D
            let newTexture = context.device.metalDevice.makeTexture(descriptor: description)!

            let newMsaaTexture: MTLTexture?
            if context.device.capability.msaa {
                description.textureType = .type2DMultisample
                description.sampleCount = 4
                newMsaaTexture = context.device.metalDevice.makeTexture(descriptor: description)!
            } else {
                newMsaaTexture = nil
            }

            encoder.copy(from: texture, to: newTexture)
            if let msaaTexture = msaaTexture, let newMsaaTexture = newMsaaTexture {
                encoder.copy(from: msaaTexture, to: newMsaaTexture)
            }
            encoder.endEncoding()

            msaaTexture = newMsaaTexture
            texture = newTexture
        }
    }

    var textureTransform: Transform2D<TextureCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: 0, y: 1) *
                Transform2D.rotate(x: .pi) *
                Transform2D.scale(x: Float(1 / canvasLayer.size.width), y: Float(1 / canvasLayer.size.height)))
    }

    // MARK: - Drawing

    func draw(commandBuffer: MTLCommandBuffer, perform: (MTLRenderCommandEncoder) -> Void) {
        guard visible else {
            return
        }
        defer {
            needsNewTexture = false
            dirty = false
        }

        let renderPassDescription = MTLRenderPassDescriptor()

        if needsNewTexture {
            createNewTexture(commandBuffer: commandBuffer)
        }

        if context.device.capability.msaa {
            renderPassDescription.colorAttachments[0].texture = msaaTexture
            renderPassDescription.colorAttachments[0].resolveTexture = texture
            renderPassDescription.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        } else {
            renderPassDescription.colorAttachments[0].texture = texture
            renderPassDescription.colorAttachments[0].storeAction = .store
        }
        renderPassDescription.colorAttachments[0].loadAction = dirty ? .clear : .load
        renderPassDescription.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescription)!
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(canvasLayer.size.width),
            height: Double(canvasLayer.size.height),
            znear: -1,
            zfar: 1
        )
        encoder.setViewport(viewPort)
        perform(encoder)
        encoder.endEncoding()
    }

    // MARK: - render

    static let renderPipelineDescriptor: MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        descriptor.colorAttachments[0].isBlendingEnabled = true

        // alpha blending
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        return descriptor
    }()

    func render(context: Context) {
        guard visible else { return }
        buffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.size * 6)

        let encoder = context.encoder
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    var vertices: [Vertex] {
        let size = canvasLayer.size
        let width = Float(size.width)
        let height = Float(size.height)
        return [
            Vertex(
                position: SIMD2(width, 0),
                textureCoordinate: SIMD2(1.0, 1.0)
            ),
            Vertex(
                position: SIMD2(0, 0),
                textureCoordinate: SIMD2(0.0, 1.0)
            ),
            Vertex(
                position: SIMD2(0, height),
                textureCoordinate: SIMD2(0.0, 0.0)
            ),
            Vertex(
                position: SIMD2(width, 0),
                textureCoordinate: SIMD2(1.0, 1.0)
            ),
            Vertex(
                position: SIMD2(0, height),
                textureCoordinate: SIMD2(0.0, 0.0)
            ),
            Vertex(
                position: SIMD2(width, height),
                textureCoordinate: SIMD2(1.0, 0.0)
            ),
        ]
    }
}