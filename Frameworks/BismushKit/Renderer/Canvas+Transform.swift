//
//  Canvas+Transform.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

extension Canvas {
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
            Transform2D.scale(x: Float(1 / size.width), y: Float(1 / size.height)))
    }
}
