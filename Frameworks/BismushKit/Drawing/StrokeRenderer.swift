//
//  StrokeRenderer.swift
//  Bismush
//
//  Created by mzp on 4/3/22.
//

import Foundation
import Metal
import simd

class StrokeRenderer {
    private let commandQueue: MTLCommandQueue
    private let store: ArtboardStore
    private var context: BMKLayerContext

    init(store: ArtboardStore, context: BMKLayerContext) {
        self.store = store
        self.context = context
        commandQueue = store.device.metalDevice.makeCommandQueue()!
    }

    func draw(strokes: MetalMutableArray<BMKStroke>) {
        store.device.scope("\(#function)") {
            let commandBuffer = commandQueue.makeCommandBuffer()!

            store.activeLayer.render(commandBuffer: commandBuffer) { encoder in
                let descriptor = MTLRenderPipelineDescriptor()
                if store.device.capability.msaa {
                    descriptor.sampleCount = 4
                } else {
                    descriptor.sampleCount = 1
                }
                descriptor.colorAttachments[0].pixelFormat = store.activeLayer.pixelFormat
                descriptor.vertexFunction = store.device.resource.function(.brushVertex)
                descriptor.fragmentFunction = store.device.resource.function(.brushFragment)
                let renderPipelineState = try! store.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
                encoder.setRenderPipelineState(renderPipelineState)

                encoder.setVertexBuffer(strokes.content, offset: 0, index: 0)
                encoder.setVertexBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 1)
                encoder.setVertexTexture(store.activeLayer.texture, index: 2)

                encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(strokes.count))
            }
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }

    func dump(buffer: MTLBuffer, count: Int) {
        let array = Array(
            UnsafeBufferPointer(start: buffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: count),
                                count: count)
        )
        BismushLogger.dev.debug("\(array)")
    }
}
