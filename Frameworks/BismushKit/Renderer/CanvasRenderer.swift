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

    private let document: CanvasDocument
    private let layerRenderer: CanvasLayerRenderer
    private let commandQueue: MTLCommandQueue

    public init(document: CanvasDocument) {
        self.document = document
        layerRenderer = CanvasLayerRenderer(document: document)

        commandQueue = document.device.metalDevice.makeCommandQueue()!
    }

    // MARK: - Render

    private func renderCanvasIfNeeded() {
        defer {
            document.canvasTexture.needsLayout = false
        }
        guard document.canvasTexture.needsLayout else {
            return
        }
        document.device.scope("\(#function)") {
            let canvasLayer = self.document.activeLayer
            let commandBuffer = commandQueue.makeCommandBuffer()!

            let size = document.canvas.size

            document.canvasTexture.makeWritable(commandBuffer: commandBuffer)
            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: document.canvasTexture.renderPassDescriptor
            )!
            let viewPort = MTLViewport(
                originX: 0,
                originY: 0,
                width: Double(size.width),
                height: Double(size.height),
                znear: -1,
                zfar: 1
            )
            encoder.setViewport(viewPort)

            let context = CanvasLayerRenderer.Context(
                encoder: encoder,
                projection: Transform2D(matrix: canvasLayer.renderTransform.matrix),
                pixelFormat: canvasLayer.pixelFormat,
                rasterSampleCount: 4,
                isBlendingEnabled: false
            )
            for layer in document.canvas.layers.reversed() where layer.visible {
                layerRenderer.render(canvasLayer: layer, context: context)
                if document.activeLayer == layer, let activeTexture = document.activeTexture {
                    layerRenderer.render(texture: activeTexture, context: context)
                }
            }

            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }

    public func render(context: Context) {
        renderCanvasIfNeeded()

        let canvas = document.canvas
        let projection = canvas.projection(viewPortSize: context.viewPortSize) * canvas.modelViewMatrix
        let context = CanvasLayerRenderer.Context(
            encoder: context.encoder,
            projection: projection,
            pixelFormat: .bgra8Unorm,
            isBlendingEnabled: false
        )
        layerRenderer.render(texture: document.canvasTexture, context: context)
        /*        for layer in document.canvas.layers.reversed() where layer.visible {
             layerRenderer.render(canvasLayer: layer, context: context)
             if document.activeLayer == layer, let activeTexture = document.activeTexture {
                 layerRenderer.render(texture: activeTexture, context: context)
             }
         }*/
    }
}
