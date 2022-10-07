//
//  BismushTextureDescriptor.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/29/22.
//

import Foundation

struct BismushTextureDescriptior: Codable, Equatable, Hashable {
    var size: Size<TexturePixelCoordinate>
    var pixelFormat: MTLPixelFormat
    var rasterSampleCount: Int
    var tileSize: TextureTileSize?
}
