//
//  SessionCommit.swift
//  Bismush
//
//  Created by Hiro Mizuno on 7/11/22.
//

import Foundation

class SessionCommit {
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

            // render target: texture
            // render layer: layer(active, texture)
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
            encoder.setVertexBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 1)
            encoder.setVertexTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 2)
            encoder.setFragmentBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 0)
            encoder.setFragmentTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: Int(strokes.count))
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: Int(strokes.count))

            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
