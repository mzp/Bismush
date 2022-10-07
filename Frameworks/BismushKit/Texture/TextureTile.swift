//
//  TextureTile.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/28/22.
//

import Foundation
import Metal

struct TextureTileSize: Equatable, Codable, Hashable {
    var width: Int
    var height: Int
}

struct TextureTileRegion: Equatable, Codable, Hashable {
    var x: Int
    var y: Int
    var size: TextureTileSize

    func tiles(size tileSize: TextureTileSize) -> Set<TextureTileRegion> {
        assert(size.width.isMultiple(of: size.width) && size.height.isMultiple(of: size.height))

        var tiles = Set<TextureTileRegion>()
        for tileY in stride(
            from: y,
            to: y + size.height,
            by: tileSize.height
        ) {
            for tileX in stride(
                from: x, to:
                x + size.width,
                by: tileSize.height
            ) {
                tiles.insert(.init(x: tileX, y: tileY, size: tileSize))
            }
        }
        return tiles
    }
}
