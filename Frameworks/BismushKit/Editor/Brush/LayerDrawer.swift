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
    private var context: MetalObject<BMKLayerContext>

    var dirty = true

    init(document: CanvasDocument, context: MetalObject<BMKLayerContext>) {
        self.document = document
        self.context = context
        commandQueue = document.device.metalDevice.makeCommandQueue()!
    }

    func draw(strokes: MetalMutableArray<BMKStroke>) {
        BismushLogger.drawing.trace("\(BismushInspector.array(metalArray: strokes))")
        document.device.scope("\(#function)") {
            let canvasLayer = self.document.activeLayer
            guard canvasLayer.visible else {
                return
            }
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let texture = document.texture(canvasLayer: canvasLayer)
            texture.makeWritable(commandBuffer: commandBuffer)
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: texture.renderPassDescriptor)!
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
            let renderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            encoder.setRenderPipelineState(renderPipelineState)

            encoder.setVertexBuffer(strokes.content, offset: 0, index: 0)
            encoder.setVertexBuffer(context.buffer, offset: 0, index: 1)
            encoder.setVertexTexture(document.activeTexture.texture, index: 0)

            encoder.setFragmentBuffer(context.buffer, offset: 0, index: 0)
            encoder.setFragmentTexture(document.activeTexture.texture, index: 1)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(strokes.count))

            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
