//
//  InputEvent.swift
//  Bismush
//
//  Created by mzp on 4/23/22.
//

import Foundation

public struct PressurePoint: CustomDebugStringConvertible, CustomStringConvertible {
    public var point: Point<ViewCoordinate> {
        Point(rawValue: rawValue.xy)
    }

    public var pressure: Float {
        rawValue.z
    }

    var rawValue: SIMD3<Float>

    public init(point: Point<ViewCoordinate>, pressure: Float) {
        rawValue = SIMD3(point.rawValue, pressure)
    }

    public var debugDescription: String {
        "PressurePoint(point: \(point), pressure: \(pressure))"
    }

    public var description: String {
        "(\(point.x), \(point.y), \(pressure))"
    }

    static func * (transform: Transform2D<LayerPixelCoordinate, ViewCoordinate>, event: PressurePoint) -> SIMD3<Float> {
        let point = transform * event.point
        return .init(point.rawValue, event.pressure)
    }
}
