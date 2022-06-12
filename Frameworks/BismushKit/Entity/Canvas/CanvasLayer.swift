//
//  CanvasLayer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//
import SwiftUI

public enum LayerType: Codable, Equatable, Hashable {
    case data(_: Data)
    case empty

    // For debug
    case builtin(name: String)
}

public struct CanvasLayer: Codable, Equatable, Hashable, Identifiable {
    public var id: String {
        name
    }

    public var name: String
    var layerType: LayerType
    var size: Size<CanvasPixelCoordinate>
    public var visible = true
    // TODO: implicit assume: same size, position as canvas
}
