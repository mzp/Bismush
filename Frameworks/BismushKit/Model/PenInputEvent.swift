//
//  InputEvent.swift
//  Bismush
//
//  Created by mzp on 4/23/22.
//

import Foundation

public struct PenInputEvent: CustomDebugStringConvertible {
    public var point: Point<ViewCoordinate>
    public var pressure: Float

    public init(point: Point<ViewCoordinate>, pressure: Float) {
        self.point = point
        self.pressure = pressure
    }

    public var debugDescription: String {
        "PenInput(point: \(point), pressure: \(pressure)"
    }
}
