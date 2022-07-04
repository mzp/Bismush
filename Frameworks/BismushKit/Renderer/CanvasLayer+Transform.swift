//
//  CanvasLayer+Transform.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

import Foundation

extension CanvasLayer {
    var transform: Transform2D<LayerPixelCoordinate, CanvasPixelCoordinate> {
        .identity()
    }

    var renderTransform: Transform2D<LayerCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: -1, y: -1) *
                Transform2D.scale(x: Float(1 / size.width * 2), y: Float(1 / size.height * 2)))
    }

    var textureTransform: Transform2D<TextureCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.scale(x: Float(1 / size.width), y: Float(1 / size.height)))
    }
}
