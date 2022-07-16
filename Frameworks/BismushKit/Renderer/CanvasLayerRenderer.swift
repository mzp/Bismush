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
        var pixelFormat: MTLPixelFormat
        var rasterSampleCount: Int = 1
    }

    private let document: CanvasDocument
    var needsNewTexture = false

    init(document: CanvasDocument) {
        self.document = document
    }

    // MARK: - render

    func makeRenderPipelineDescriptor(context: Context) -> MTLRenderPipelineDescriptor {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.rasterSampleCount = context.rasterSampleCount
        descriptor.colorAttachments[0].pixelFormat = context.pixelFormat

        descriptor.colorAttachments[0].isBlendingEnabled = true

        // alpha blending
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        return descriptor
    }

    func render(canvasLayer: CanvasLayer, context: Context) {
        // TODO: render active texture
        guard canvasLayer.visible else { return }
        let texture = document.texture(canvasLayer: canvasLayer)
        render(texture: texture, context: context)
    }

    func render(texture: LayerTexture, context: Context) {
        let descriptor = makeRenderPipelineDescriptor(context: context)
        descriptor.vertexFunction = document.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = document.device.resource.function(.layerFragment)
        let renderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
        let encoder = context.encoder
        encoder.setRenderPipelineState(renderPipelineState)

        var vertices = vertices(size: texture.canvasLayer.size)
        encoder.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * vertices.count, index: 0)

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)

        encoder.setFragmentTexture(texture.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    // MARK: - Vertex

    private struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
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
