//
//  SessionCommit.swift
//  Bismush
//
//  Created by Hiro Mizuno on 7/11/22.
//

import Foundation

class SessionCommit {
    private let document: CanvasDocument
    private let renderer: CanvasLayerRenderer

    init(document: CanvasDocument) {
        self.document = document
        renderer = CanvasLayerRenderer(
            document: document,
            pixelFormat: document.canvas.pixelFormat,
            rasterSampleCount: document.rasterSampleCount
        )
    }

    func commit(commandBuffer: SequencialCommandBuffer) {
        guard let activeTexture = document.activeTexture else {
            return
        }

        let canvasLayer = document.activeLayer
        let texture = document.texture(canvasLayer: canvasLayer)
        let targetTexture = texture.texture

        texture.asRenderTarget(commandBuffer: commandBuffer) { renderPassDescriptor in
            BismushLogger.texture.trace("\(#function)")
            commandBuffer.render(label: #fileID, descriptor: renderPassDescriptor) { encoder in
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
            }
        }
    }
}
