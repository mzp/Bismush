//
//  TextureTileRegion.swift
//  Bismush
//
//  Created by mzp on 10/7/22.
//

import Foundation

struct TextureTileSize: Equatable, Codable, Hashable, CustomStringConvertible {
    var width: Int
    var height: Int

    var description: String {
        "(\(width), \(height))"
    }
}

struct TextureTileRegion: Equatable, Codable, Hashable, CustomStringConvertible {
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

    var description: String {
        "Region(\(x), \(y), \(size.width), \(size.height))"
    }
}

extension Rect where T == TexturePixelCoordinate {
    func split(cover rect: Rect<TexturePixelCoordinate>, tileSize: TextureTileSize) -> Set<TextureTileRegion> {
        let minX = max(
            Int(origin.x),
            Int(floor(rect.origin.x / Float(tileSize.width))) * tileSize.width
        )
        let minY = max(
            Int(origin.y),
            Int(floor(rect.origin.y / Float(tileSize.height))) * tileSize.height
        )
        let maxX = min(
            Int(origin.x + size.width),
            Int(ceil((rect.origin.x + rect.size.width) / Float(tileSize.width))) * tileSize.width
        )
        let maxY = min(
            Int(origin.y + size.height),
            Int(ceil((rect.origin.y + rect.size.height) / Float(tileSize.height))) * tileSize.height
        )

        return TextureTileRegion(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        ).tiles(
            size: tileSize
        )
    }
}
