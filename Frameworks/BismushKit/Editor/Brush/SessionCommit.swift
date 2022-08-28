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
    private let renderer: CanvasLayerRenderer

    init(document: CanvasDocument, context: BMKLayerContext) {
        self.document = document
        self.context = context
        renderer = CanvasLayerRenderer(
            document: document,
            pixelFormat: document.canvas.pixelFormat,
            rasterSampleCount: document.rasterSampleCount
        )
        commandQueue = document.device.metalDevice.makeCommandQueue()!
    }

    func commit() {
        document.device.scope("\(#function)") {
            guard let activeTexture = document.activeTexture else {
                return
            }

            let canvasLayer = self.document.activeLayer
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let texture = document.texture(canvasLayer: canvasLayer)
            let targetTexture = texture.texture

            texture.withRenderPassDescriptor(commandBuffer: commandBuffer) { renderPassDescriptor in
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

                renderer.render(
                    textures: [activeTexture],
                    context: .init(
                        encoder: encoder,
                        projection: Transform2D(matrix: canvasLayer.renderTransform.matrix),
                        pixelFormat: canvasLayer.pixelFormat,
                        blend: .strictAlphaBlend(target: targetTexture)
                    )
                )

                encoder.endEncoding()
            }

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
