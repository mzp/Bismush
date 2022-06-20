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

    public var canvas: Canvas {
        document.canvas
    }

//    public var layerRenderers = [CanvasLayerRenderer]()

    private let document: CanvasDocument
    private let layerRenderer: CanvasLayerRenderer

    public let device: GPUDevice

    init(document: CanvasDocument) {
        self.document = document
        device = GPUDevice(metalDevice: MTLCreateSystemDefaultDevice()!)
        layerRenderer = CanvasLayerRenderer(document: document)
        /*        layerRenderers = document.canvas.layers.map { layer in
             CanvasLayerRenderer(
                 canvasLayer: layer,
                 documentContext: document,
                 renderContext: self
             )
         }*/
    }

    var canvasSize: Size<CanvasPixelCoordinate> {
        canvas.size
    }

    /*    var activeLayer: CanvasLayerRenderer {
         layerRenderers.first!
     }*/

    // MARK: - Undo/redo

    /*    public func getSnapshot() -> Snapshot {
         BismushLogger.drawing.info("get snapshot")
         let snapshot = Snapshot(texture: activeLayer.texture, msaaTexture: activeLayer.msaaTexture)
         activeLayer.needsNewTexture = true
         return snapshot
     }

     public func restore(snapshot: Snapshot) {
         BismushLogger.drawing.info("resotre from snapshot")
         activeLayer.texture = snapshot.texture
         activeLayer.msaaTexture = snapshot.msaaTexture
     }*/

    // MARK: - Transform

    /*
     func normalize(viewPortSize: Size<ViewCoordinate>) -> Transform2D<ViewCoordinate, ViewPortCoordinate> {
         Transform2D(matrix:
             Transform2D.scale(x: viewPortSize.width / 2, y: viewPortSize.height / 2) *
                 Transform2D.translate(x: 1, y: 1))
     }

     func projection(viewPortSize: Size<ViewCoordinate>) -> Transform2D<ViewPortCoordinate, WorldCoordinate> {
         let aspectRatio = Float(viewPortSize.height / viewPortSize.width)
         return Transform2D(matrix:
             Transform2D.scale(x: aspectRatio, y: 1) *
                 Transform2D.translate(x: -1, y: -1) *
                 Transform2D.scale(x: 2, y: 2)
         )
     }

     var modelViewMatrix: Transform2D<WorldCoordinate, CanvasPixelCoordinate> {
         Transform2D(matrix:
             Transform2D.scale(x: Float(1 / canvas.size.width), y: Float(1 / canvas.size.height)))
     }*/

    // MARK: - Render

    public func render(context: Context) {
        let context = CanvasLayerRenderer.Context(
            encoder: context.encoder,
            projection: document.canvas.projection(viewPortSize: context.viewPortSize) * document.canvas.modelViewMatrix
        )
        for layer in document.canvas.layers {
            layerRenderer.render(canvasLayer: layer, context: context)
        }
    }
}
