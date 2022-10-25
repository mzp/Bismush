//
//  StrokeRenderer.swift
//  Bismush
//
//  Created by mzp on 4/3/22.
//

import Foundation
import Metal
import simd

class LayerDrawer {
    private let document: CanvasDocument
    private let renderPipelineState: MTLRenderPipelineState
    var dirty = true

    init(document: CanvasDocument) {
        self.document = document

        renderPipelineState = try! document.device.makeRenderPipelineState { descriptor in
            descriptor.label = #fileID
            descriptor.rasterSampleCount = document.rasterSampleCount
            descriptor.colorAttachments[0].pixelFormat = document.activeLayer.pixelFormat
            descriptor.vertexFunction = document.device.resource.function(.brushVertex)
            descriptor.fragmentFunction = document.device.resource.function(.brushFragment)
        }
    }

    func draw(
        region: Rect<TexturePixelCoordinate>,
        strokes: MetalMutableArray<BMKStroke>,
        context: inout BMKLayerContext,
        commandBuffer: SequencialCommandBuffer
    ) {
        document.needsRenderCanvas = true
        guard let texture = document.activeTexture else {
            return
        }
        let canvasLayer = document.activeLayer
        guard canvasLayer.visible else {
            return
        }
        texture.asRenderTarget(
            region: region,
            commandBuffer: commandBuffer,
            useMSAA: true
        ) { renderPassDescriptor in
            BismushLogger.texture.trace("\(#function)")
            commandBuffer.render(
                label: #fileID,
                descriptor: renderPassDescriptor
            ) { encoder in
                let viewPort = MTLViewport(
                    originX: 0,
                    originY: 0,
                    width: Double(canvasLayer.size.width),
                    height: Double(canvasLayer.size.height),
                    znear: -1,
                    zfar: 1
                )
                encoder.setViewport(viewPort)
                encoder.setRenderPipelineState(renderPipelineState)
                encoder.setVertexBuffer(strokes.content, offset: 0, index: 0)
                encoder.setVertexBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 1)
                encoder.setVertexTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 2)
                encoder.setFragmentBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 0)
                encoder.setFragmentTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 1)

                encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(strokes.count))
            }
        }
    }
}
