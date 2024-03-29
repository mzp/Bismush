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

// top left: (0,0) bottom right: (canvas.width, canvas.height)
public class CanvasPixelCoordinate: Coordinate {}

// top left: (0,0) bottom right: (layer.width, layer.height)
public class LayerPixelCoordinate: Coordinate {}

// left top: (-1, -1) top right: (1, 1)
public class LayerCoordinate: Coordinate {}

// left bottom: (0, 0) top right (1, 1)
public class TextureCoordinate: Coordinate {}

public class TexturePixelCoordinate: Coordinate {}

public struct Size<T: Coordinate>: Codable, CustomStringConvertible, Equatable, Hashable {
    var rawValue: SIMD2<Float>

    public var width: Float {
        get { rawValue.x }
        set { rawValue.x = newValue }
    }

    public var height: Float {
        get { rawValue.y }
        set { rawValue.y = newValue }
    }

    public init(width: Float, height: Float) {
        rawValue = SIMD2(width, height)
    }

    public init(cgSize: CGSize) {
        rawValue = SIMD2(Float(cgSize.width), Float(cgSize.height))
    }

    public init<U>(_ other: Size<U>) {
        rawValue = other.rawValue
    }

    public static func zero() -> Size<T> {
        Size(width: 0, height: 0)
    }

    public var description: String {
        "Size<\(rawValue) in \(T.self)>"
    }
}

public struct Point<T: Coordinate>: Codable, CustomStringConvertible, Equatable, Hashable {
    var rawValue: SIMD2<Float>

    public var x: Float {
        get { rawValue.x }
        set { rawValue.x = newValue }
    }

    public var y: Float {
        get { rawValue.y }
        set { rawValue.y = newValue }
    }

    static func zero<T>() -> Point<T> {
        .init(x: 0, y: 0)
    }

    public init(rawValue: SIMD2<Float>) {
        self.rawValue = rawValue
    }

    public var description: String {
        "Point<\(rawValue) in \(T.self)>"
    }

    public init(float4: SIMD4<Float>) {
        self.init(x: float4.x / float4.w, y: float4.y / float4.w)
    }

    public init(x: Float, y: Float) {
        self.init(rawValue: SIMD2(x, y))
    }

    public init(cgPoint: CGPoint) {
        rawValue = SIMD2(Float(cgPoint.x), Float(cgPoint.y))
    }

    var float4: SIMD4<Float> {
        SIMD4(SIMD3(rawValue, 0), 1)
    }
}
