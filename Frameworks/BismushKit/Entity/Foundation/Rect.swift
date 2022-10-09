//
//  Rect.swift
//  Bismush
//
//  Created by Hiro Mizuno on 10/9/22.
//

import Foundation

public struct Rect<T: Coordinate>: Codable, Equatable, Hashable {
    public var origin: Point<T>
    public var size: Size<T>

    public init(origin: Point<T>, size: Size<T>) {
        self.origin = origin
        self.size = size
    }

    public init(x: Float, y: Float, width: Float, height: Float) {
        origin = .init(x: x, y: y)
        size = .init(width: width, height: height)
    }

    public init(points: [Point<T>]) {
        var minX: Float = 0.0
        var minY: Float = 0.0
        var maxX: Float = 0.0
        var maxY: Float = 0.0
        for point in points {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        origin = .init(x: minX, y: minY)
        size = .init(width: maxX - minX, height: maxY - minY)
    }

    public mutating func add(insets: NSEdgeInsets) {
        origin.x += Float(insets.left)
        origin.y += Float(insets.top)
        size.width -= Float(insets.left + insets.right)
        size.height -= Float(insets.top + insets.bottom)
    }
}
