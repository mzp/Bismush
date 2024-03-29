//
//  Cavas.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/21/22.
//

import CoreGraphics
import Foundation

public struct Canvas: Identifiable, Codable, Equatable {
    public var layers: [CanvasLayer]
    public var size: Size<CanvasPixelCoordinate>
    var pixelFormat: MTLPixelFormat = .rgba8Unorm

    public var id: String {
        "the canvas" // FIXME: Support multiple canvas
    }

    public static let sample: Canvas = {
        let size: Size<CanvasPixelCoordinate> = .init(width: 800, height: 800)
        return .init(
            layers: [
                CanvasLayer(name: "#1", layerType: .empty, size: size),
                CanvasLayer(name: "#2", layerType: .empty, size: size),
                CanvasLayer(name: "square", layerType: .builtin(name: "square"), size: size),
                CanvasLayer(name: "yosemite", layerType: .builtin(name: "yosemite"), size: size),
            ],
            size: size
        )
    }()

    public static let empty: Canvas = {
        let size: Size<CanvasPixelCoordinate> = .init(width: 800, height: 800)
        return .init(
            layers: [
                CanvasLayer(name: "#1", layerType: .empty, size: size),
            ],
            size: size
        )
    }()
}
