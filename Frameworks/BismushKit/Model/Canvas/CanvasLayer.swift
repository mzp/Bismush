//
//  CanvasLayer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//

public enum LayerType: Codable, Equatable, Hashable {
    case empty

    // For debug
    case builtin(name: String)
}

public struct CanvasLayer: Codable, Equatable, Hashable {
    public var id: String {
        name
    }

    public var name: String
    var layerType: LayerType
    var size: Size<CanvasPixelCoordinate>
    // TODO: implicit assume: same size, position as canvas
}
