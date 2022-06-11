//
//  Cavas.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/21/22.
//

import CoreGraphics
import Foundation

public struct Canvas: Codable {
    public var layers: [CanvasLayer]
    public var size: Size<CanvasPixelCoordinate>
}
