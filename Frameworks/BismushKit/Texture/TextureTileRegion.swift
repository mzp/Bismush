//
//  TextureTileRegion.swift
//  Bismush
//
//  Created by mzp on 10/7/22.
//

import Foundation

struct TextureTileSize: Equatable, Codable, Hashable {
    var width: Int
    var height: Int
}

struct TextureTileRegion: Equatable, Codable, Hashable {
    var x: Int
    var y: Int
    var size: TextureTileSize

    init(x: Int, y: Int, size: TextureTileSize) {
        self.x = x
        self.y = y
        self.size = size
    }

    init(x: Int, y: Int, width: Int, height: Int) {
        self.init(x: x, y: y, size: .init(width: width, height: height))
    }

    func tiles(size tileSize: TextureTileSize) -> Set<TextureTileRegion> {
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
                tiles.insert(.init(
                    x: tileX,
                    y: tileY,
                    size: .init(
                        width: min(tileSize.width, size.width + x - tileX),
                        height: min(tileSize.height, size.height + y - tileY)
                    )
                )
                )
            }
        }
        return tiles
    }

    static func cover(rect: Rect<TexturePixelCoordinate>, size: TextureTileSize) -> Set<TextureTileRegion> {
        let x = Int(floor(rect.origin.x / Float(size.width))) * size.width
        let y = Int(floor(rect.origin.y / Float(size.height))) * size.height
        let width = Int(ceil(rect.size.width / Float(size.width))) * size.width
        let height = Int(ceil(rect.size.height / Float(size.height))) * size.height

        return TextureTileRegion(x: x, y: y, width: width, height: height)
            .tiles(size: size)
    }
}
