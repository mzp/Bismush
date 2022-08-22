//
//  CanvasLayerStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/31/22.
//

import Metal
import simd

public class CanvasLayerRenderer {
    enum Blend {
        /// GPU-powered blending. This works only when the destinationColor.w == 1.0
        case alphaBlending

        /// Precise alpha blending. https://qiita.com/kerupani129/items/4bf75d9f44a5b926df58
        case strictAlphaBlend(target: MTLTexture)
    }

    struct Context {
        var encoder: MTLRenderCommandEncoder
        var projection: Transform2D<ViewPortCoordinate, CanvasPixelCoordinate>
        var pixelFormat: MTLPixelFormat
        var blend: Blend = .alphaBlending
    }

    private let document: CanvasDocument
    var needsNewTexture = false
    let strictAlphaBlendRenderPipelineState: MTLRenderPipelineState
    let alphaBlendRenderPipelineState: MTLRenderPipelineState

    init(document: CanvasDocument, pixelFormat: MTLPixelFormat, rasterSampleCount: Int) {
        self.document = document

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.rasterSampleCount = rasterSampleCount
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.vertexFunction = document.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = document.device.resource.function(.layerCopy)
        strictAlphaBlendRenderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)

        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation = .max
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        descriptor.vertexFunction = document.device.resource.function(.layerVertex)
        descriptor.fragmentFunction = document.device.resource.function(.layerBlend)
        alphaBlendRenderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
    }

    // MARK: - render

    func render(canvasLayer: CanvasLayer, context: Context) {
        guard canvasLayer.visible else { return }
        let texture = document.texture(canvasLayer: canvasLayer)
        render(texture: texture, context: context)
    }

    func render(texture: BismushTexture, context: Context) {
        let encoder = context.encoder

        switch context.blend {
        case .alphaBlending:
            encoder.setFragmentTexture(texture.texture, index: 0)
            encoder.setRenderPipelineState(alphaBlendRenderPipelineState)
        case let .strictAlphaBlend(target: targetTexture):
            encoder.setFragmentTexture(texture.texture, index: 0)
            encoder.setFragmentTexture(targetTexture, index: 1)
            encoder.setRenderPipelineState(strictAlphaBlendRenderPipelineState)
        }

        var vertices = vertices(size: texture.size)
        encoder.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * vertices.count, index: 0)

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    // MARK: - Vertex

    private struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }

    private func vertices(size: Size<TextureCoordinate>) -> [Vertex] {
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
