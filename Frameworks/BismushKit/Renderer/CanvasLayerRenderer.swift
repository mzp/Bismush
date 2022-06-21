//
//  CanvasLayerStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/31/22.
//

import Metal
import simd

public class CanvasLayerRenderer {
    struct Context {
        var encoder: MTLRenderCommandEncoder
        var projection: Transform2D<ViewPortCoordinate, CanvasPixelCoordinate>
    }

    struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }

    private let buffer: MTLBuffer
    private let renderPipelineState: MTLRenderPipelineState
    private let document: CanvasDocument
    var needsNewTexture = false

    init(document: CanvasDocument) {
        self.document = document

        buffer = document.device.metalDevice.makeBuffer(length: MemoryLayout<Vertex>.size * 6)!

        let descriptor = Self.renderPipelineDescriptor
        descriptor.vertexFunction = document.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = document.device.resource.function(.layerFragment)
        renderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
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

    func render(canvasLayer: CanvasLayer, context: Context) {
        guard canvasLayer.visible else { return }
        let vertices = vertices(size: canvasLayer.size)
        buffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.size * 6)
        let texture = document.texture(canvasLayer: canvasLayer)

        let encoder = context.encoder
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    private func vertices(size: Size<CanvasPixelCoordinate>) -> [Vertex] {
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
