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

    init(document: CanvasDocument, store: CanvasRenderer, context: BMKLayerContext) {
        self.document = document
        self.context = context
        commandQueue = store.device.metalDevice.makeCommandQueue()!
    }

    func draw(strokes: MetalMutableArray<BMKStroke>) {
        document.device.scope("\(#function)") {
            let canvasLayer = document.activeLayer
            guard canvasLayer.visible else {
                return
            }
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let renderPassDescription = MTLRenderPassDescriptor()
            let texture = document.texture(canvasLayer: canvasLayer)
            if let msaaTexture = document.msaaTexture(canvasLayer: canvasLayer) {
                renderPassDescription.colorAttachments[0].texture = msaaTexture
                renderPassDescription.colorAttachments[0].resolveTexture = texture
                renderPassDescription.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            } else {
                renderPassDescription.colorAttachments[0].texture = texture
                renderPassDescription.colorAttachments[0].storeAction = .store
            }
            renderPassDescription.colorAttachments[0].loadAction = .load
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

            let descriptor = MTLRenderPipelineDescriptor()
            if document.device.capability.msaa {
                descriptor.sampleCount = 4
            } else {
                descriptor.sampleCount = 1
            }
            descriptor.colorAttachments[0].pixelFormat = document.activeLayer.pixelFormat
            descriptor.vertexFunction = document.device.resource.function(.brushVertex)
            descriptor.fragmentFunction = document.device.resource.function(.brushFragment)
            let renderPipelineState = try! document.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            encoder.setRenderPipelineState(renderPipelineState)

            encoder.setVertexBuffer(strokes.content, offset: 0, index: 0)
            encoder.setVertexBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 1)
            encoder.setVertexTexture(document.texture(canvasLayer: document.activeLayer), index: 2)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(strokes.count))

            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
