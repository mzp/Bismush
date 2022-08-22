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
    private let commandQueue: MTLCommandQueue
    private var context: BMKLayerContext

    var dirty = true

    init(document: CanvasDocument, context: BMKLayerContext) {
        self.document = document
        self.context = context
        commandQueue = document.device.metalDevice.makeCommandQueue()!
    }

    func draw(strokes: MetalMutableArray<BMKStroke>) {
        document.needsRenderCanvas = true
        document.device.scope("\(#function)") {
            guard let texture = document.activeTexture else {
                return
            }
            let canvasLayer = self.document.activeLayer
            guard canvasLayer.visible else {
                return
            }
            let commandBuffer = commandQueue.makeCommandBuffer()!

            texture.withRenderPassDescriptor { renderPassDescriptor in
                let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                let viewPort = MTLViewport(
                    originX: 0,
                    originY: 0,
                    width: Double(canvasLayer.size.width),
                    height: Double(canvasLayer.size.height),
                    znear: -1,
                    zfar: 1
                )
                encoder.setViewport(viewPort)

                let descriptor = MTLRenderPipelineDescriptor()
                if document.device.capability.msaa {
                    descriptor.rasterSampleCount = 4
                } else {
                    descriptor.rasterSampleCount = 1
                }

                descriptor.colorAttachments[0].pixelFormat = document.activeLayer.pixelFormat
                descriptor.vertexFunction = document.device.resource.function(.brushVertex)
                descriptor.fragmentFunction = document.device.resource.function(.brushFragment)
                let renderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(
                    descriptor: descriptor
                )
                encoder.setRenderPipelineState(renderPipelineState)

                encoder.setVertexBuffer(strokes.content, offset: 0, index: 0)
                encoder.setVertexBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 1)
                encoder.setVertexTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 2)
                encoder.setFragmentBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 0)
                encoder.setFragmentTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 1)

                encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(strokes.count))

                encoder.endEncoding()
            }
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
