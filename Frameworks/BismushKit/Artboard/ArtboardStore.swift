//
//  ArtboardStore.swift
//  Bismush
//
//  Created by mzp on 3/23/22.
//

import Foundation
import Metal
import simd
import SwiftUI

public struct Snapshot {
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}

public class ArtboardStore: RenderContext, ObservableObject {
    struct Context {
        var encoder: MTLRenderCommandEncoder
        var viewPortSize: Size<ViewCoordinate>
    }

    public let canvas: Canvas
    public var layers = [ArtboardLayerStore]()

    let device: GPUDevice

    init(canvas: Canvas, dataContext: DataContext) {
        self.canvas = canvas
        device = GPUDevice(metalDevice: MTLCreateSystemDefaultDevice()!)
        layers = canvas.layers.map { layer in
            ArtboardLayerStore(canvasLayer: layer, dataContext: dataContext, renderContext: self)
        }
    }

    var canvasSize: Size<CanvasPixelCoordinate> {
        canvas.size
    }

    var activeLayer: ArtboardLayerStore {
        layers.first!
    }

    // MARK: - Undo/redo

    public func getSnapshot() -> Snapshot {
        BismushLogger.drawing.info("get snapshot")
        let snapshot = Snapshot(texture: activeLayer.texture, msaaTexture: activeLayer.msaaTexture)
        activeLayer.needsNewTexture = true
        return snapshot
    }

    public func restore(snapshot: Snapshot) {
        BismushLogger.drawing.info("resotre from snapshot")
        activeLayer.texture = snapshot.texture
        activeLayer.msaaTexture = snapshot.msaaTexture
    }

    // MARK: - Transform

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
    }

    // MARK: - Render

    func render(context: Context) {
        let context = ArtboardLayerStore.Context(
            encoder: context.encoder,
            projection: projection(viewPortSize: context.viewPortSize) * modelViewMatrix
        )
        for layer in layers.reversed() {
            layer.render(context: context)
        }
    }
}
