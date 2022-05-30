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

public class ArtboardStore: CanvasContext {
    let canvas: Canvas
    let device: GPUDevice
    private(set) var layers = [ArtboardLayerStore]()

    public init(canvas: Canvas) {
        self.canvas = canvas
        device = GPUDevice(metalDevice: MTLCreateSystemDefaultDevice()!)
        layers = canvas.layers.map { layer in
            ArtboardLayerStore(canvasLayer: layer, context: self)
        }
    }

    public static func makeSample() -> ArtboardStore {
        .init(canvas: Canvas(
            layers: [
                CanvasLayer(layerType: .empty, size: Size(width: 800, height: 800)),
            ],
            size: Size(width: 800, height: 800)
        ))
    }

    var canvasSize: Size<CanvasPixelCoordinate> {
        canvas.size
    }

    var activeLayer: ArtboardLayerStore {
        layers.first!
    }

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
}