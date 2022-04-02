//
//  Coordinate.swift
//  Bismush
//
//  Created by mzp on 4/2/22.
//

import CoreGraphics

public class Coordinate {}

// left bottom: (0, 0) top right: (view.width, view.height)
public class ViewCoordinate: Coordinate {}

// left bottom: (-1, -1) top right: (1, 1)
public class ViewPortCoordinate: Coordinate {}

// left bottom: (0,0) top right: (1, 1)
public class WorldCoordinate: Coordinate {}

// left bottom: (0,0) top right: (canvas.width, canvas.height)
public class CanvasPixelCoordinate: Coordinate {}

// left bottom: (0,0) top right: (layer.width, layer.height)
public class LayerPixelCoordinate: Coordinate {}

// left bottom: (-1, -1) top right: (1, 1)
public class LayerCoordinate: Coordinate {}

public struct Size<T: Coordinate>: Codable, CustomStringConvertible {
    var rawValue: SIMD2<Float>

    var width: Float { rawValue.x }
    var height: Float { rawValue.y }

    init(width: Float, height: Float) {
        rawValue = SIMD2(width, height)
    }

    public init(cgSize: CGSize) {
        rawValue = SIMD2(Float(cgSize.width), Float(cgSize.height))
    }

    static func zero() -> Size<T> {
        Size(width: 0, height: 0)
    }

    public var description: String {
        "Size<\(rawValue) in \(T.self)>"
    }
}

public struct Point<T: Coordinate>: Codable, CustomStringConvertible {
    var rawValue: SIMD2<Float>

    public var description: String {
        "Point<\(rawValue) in \(T.self)>"
    }

    public init(x: Float, y: Float) {
        rawValue = SIMD2(x, y)
    }

    public init(cgPoint: CGPoint) {
        rawValue = SIMD2(Float(cgPoint.x), Float(cgPoint.y))
    }
}
