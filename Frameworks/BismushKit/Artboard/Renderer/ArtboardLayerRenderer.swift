//
//  LayerRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/24/22.
//

import Foundation
import Metal
import simd

class ArtboardLayerRenderer {
    struct Context {
        var encoder: MTLRenderCommandEncoder
        var projection: Transform2D<ViewPortCoordinate, CanvasPixelCoordinate>
    }

    struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }

    let buffer: MTLBuffer
    let renderPipelineState: MTLRenderPipelineState
    let store: ArtboardLayerStore

    init(store: ArtboardLayerStore) {
        self.store = store

        buffer = store.device.metalDevice.makeBuffer(length: MemoryLayout<Vertex>.size * 6)!

        let descriptor = Self.renderPipelineDescriptor
        descriptor.vertexFunction = store.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = store.device.resource.function(.layerFragment)
        renderPipelineState = try! store.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
    }

    static let renderPipelineDescriptor: MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true

        // alpha blending
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
        return descriptor
    }()

    func render(context: Context) {
        buffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.size * 6)

        let encoder = context.encoder
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)
        encoder.setFragmentTexture(store.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    // MARK: - Debug stuff

    var vertices: [Vertex] {
        let size = store.canvasLayer.size
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
