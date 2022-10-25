//
//  CanvasRenderer.swift
//  Bismush
//
//  Created by mzp on 3/23/22.
//

import Foundation
import Metal
import simd
import SwiftUI

public class CanvasRenderer: ObservableObject {
    public struct Context {
        var encoder: MTLRenderCommandEncoder
        var viewPortSize: Size<ViewCoordinate>

        public init(encoder: MTLRenderCommandEncoder, viewPortSize: Size<ViewCoordinate>) {
            self.encoder = encoder
            self.viewPortSize = viewPortSize
        }
    }

    private var document: CanvasDocument
    private let layerRenderer: CanvasLayerRenderer
    private let canvasRenderer: CanvasLayerRenderer
    private let commandQueue: CommandQueue

    public init(document: CanvasDocument, pixelFormat: MTLPixelFormat? = nil, rasterSampleCount: Int = 1) {
        self.document = document
        layerRenderer = CanvasLayerRenderer(
            document: document,
            pixelFormat: document.canvas.pixelFormat,
            rasterSampleCount: document.rasterSampleCount
        )
        canvasRenderer = CanvasLayerRenderer(
            document: document,
            pixelFormat: pixelFormat ?? document.canvas.pixelFormat,
            rasterSampleCount: rasterSampleCount
        )

        commandQueue = document.device.makeCommandQueue(label: #fileID)
    }

    // MARK: - Render

    private func renderCanvasIfNeeded() {
        defer {
            document.needsRenderCanvas = false
        }
        guard document.needsRenderCanvas else {
            return
        }

        document.device.scope(#function) {
            var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: #function)

            let canvasLayer = document.activeLayer

            // linearize textures
            var textures = [BismushTexture]()
            for layer in document.canvas.layers.reversed() where layer.visible {
                textures.append(document.texture(canvasLayer: layer))
                if document.activeLayer == layer, let activeTexture = document.activeTexture {
                    textures.append(activeTexture)
                }
            }

            // render to canvas texture
            document.canvasTexture.asRenderTarget(commandBuffer: commandBuffer) { renderPassDescriptor in
                BismushLogger.texture.trace("\(#function)")
                commandBuffer.render(
                    label: #fileID,
                    descriptor: renderPassDescriptor
                ) { encoder in
                    let size = document.canvas.size
                    let viewPort = MTLViewport(
                        originX: 0,
                        originY: 0,
                        width: Double(size.width),
                        height: Double(size.height),
                        znear: -1,
                        zfar: 1
                    )
                    encoder.setViewport(viewPort)
                    layerRenderer.render(
                        textures: textures,
                        context: .init(
                            encoder: encoder,
                            projection: Transform2D(matrix: canvasLayer.renderTransform.matrix),
                            pixelFormat: canvasLayer.pixelFormat
                        )
                    )
                }
            }
            commandBuffer.commit()
        }
    }

    public func render(context: Context) {
        renderCanvasIfNeeded()

        let canvas = document.canvas
        let projection = canvas.projection(viewPortSize: context.viewPortSize) * canvas.modelViewMatrix
        let context = CanvasLayerRenderer.Context(
            encoder: context.encoder,
            projection: projection,
            pixelFormat: .bgra8Unorm
        )
        canvasRenderer.render(textures: [document.canvasTexture], context: context)
    }
}
