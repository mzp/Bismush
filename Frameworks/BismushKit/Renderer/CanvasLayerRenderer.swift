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

        strictAlphaBlendRenderPipelineState = try! document.device.makeRenderPipelineState { descriptor in
            descriptor.rasterSampleCount = rasterSampleCount
            descriptor.label = "Strict Alpha blend"
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            descriptor.vertexFunction = document.device.resource.function(.layerVertex)
            descriptor.fragmentFunction = document.device.resource.function(.layerCopy)
        }

        alphaBlendRenderPipelineState = try! document.device.makeRenderPipelineState { descriptor in
            descriptor.rasterSampleCount = rasterSampleCount
            descriptor.label = "Fast blend"
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].alphaBlendOperation = .max
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
            descriptor.vertexFunction = document.device.resource.function(.layerVertex)
            descriptor.fragmentFunction = document.device.resource.function(.layerBlend)
        }
    }

    // MARK: - render

    func render(textures: [BismushTexture], context: Context) {
        let encoder = context.encoder

        switch context.blend {
        case .alphaBlending:
            encoder.setRenderPipelineState(alphaBlendRenderPipelineState)
        case let .strictAlphaBlend(target: targetTexture):
            encoder.setFragmentTexture(targetTexture, index: 1)
            encoder.setRenderPipelineState(strictAlphaBlendRenderPipelineState)
        }

        var projection = context.projection.matrix
        encoder.setVertexBytes(&projection, length: MemoryLayout<simd_float4x4>.size, index: 1)

        var previousSize: Size<TexturePixelCoordinate>?
        for texture in textures {
            if texture.size != previousSize {
                var buffer = vertices(size: texture.size)
                encoder.setVertexBytes(&buffer, length: MemoryLayout<Vertex>.stride * buffer.count, index: 0)
                previousSize = texture.size
            }
            encoder.setFragmentTexture(texture.texture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }

    // MARK: - Vertex

    private struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }

    private func vertices(size: Size<TexturePixelCoordinate>) -> [Vertex] {
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
