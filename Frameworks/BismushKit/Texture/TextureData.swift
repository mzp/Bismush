//
//  File.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/28/22.
//

import Foundation
import Metal

struct Tile: Codable, Hashable, Equatable {
    typealias ID = String
    var x: Int
    var y: Int
    var id: ID
}

protocol TextureDataDelegate: AnyObject {
    func load(tile: Tile)
}

protocol TextureDataContext {
    var device: GPUDevice { get }
    var size: Size<TexturePixelCoordinate> { get }
    var tileSize: Size<TexturePixelCoordinate> { get }
}

struct TileSequence: Sequence {
    private var mapping: [[Tile.ID?]]

    struct TileIterator: IteratorProtocol {
        var mapping: [[Tile.ID?]]
        var x: Int = 0
        var y: Int = 0

        mutating func next() -> Tile? {
            while y < mapping.count {
                while x < mapping[y].count {
                    defer { x += 1 }
                    if let id = mapping[y][x] {
                        return Tile(x: x, y: y, id: id)
                    }
                }
                x = 0
                y += 1
            }
            return nil
        }
    }

    func makeIterator() -> TileIterator {
        TileIterator(mapping: mapping)
    }

    init(mapping: [[Tile.ID?]]) {
        self.mapping = mapping
    }
}

class TextureData {
    var tiles: TileSequence {
        TileSequence(mapping: mapping)
    }
    private weak var delegate : TextureDataDelegate?
    private let context: TextureDataContext

    private var mapping: [[Tile.ID?]]

    lazy var tileSize: MTLSize = {
        MTLSize(
            width: Int(context.tileSize.width),
            height: Int(context.tileSize.height),
            depth: 1
        )
    }()

    init(
        tiles:  [Tile],
        delegate: TextureDataDelegate?,
        context: TextureDataContext
    ) {
        self.delegate = delegate
        self.context = context

        let regionSize = (context.size.rawValue / context.tileSize.rawValue).rounded(.up)
        mapping = Array(
            repeating: Array(
                repeating: nil,
                count: Int(regionSize.x)
            ),
            count: Int(regionSize.y)
        )

        for tile in tiles {
            mapping[tile.y][tile.x] = tile.id
        }
    }

    func load<T: Sequence>(points: T) where T.Element == Point<TexturePixelCoordinate> {
        var minX = Int.max
        var minY = Int.max
        var maxX = 0
        var maxY = 0

        for point in points {
            let tile = (point.rawValue / context.tileSize.rawValue).rounded(.up)

            let x = Int(point.x)
            let y = Int(point.y)

            if mapping[Int(tile.y)][Int(tile.x)] == nil {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        if minX == Int.max, minY == Int.max {
            return
        } else {
            var pixelRegion = MTLRegion(
                origin: MTLOrigin(
                    x: minX,
                    y: minY,
                    z: 0
                ),
                size: MTLSize(
                    width: maxX - minX + 1,
                    height: maxY - minY + 1,
                    depth: 1
                )
            )
            var tileRegion = MTLRegion()
            context.device.metalDevice.convertSparsePixelRegions?(
                &pixelRegion,
                toTileRegions: &tileRegion,
                withTileSize: tileSize,
                alignmentMode: .outward,
                numRegions: 1
            )

            for y in tileRegion.origin.y ..< tileRegion.origin.y + tileRegion.size.height {
                for x in tileRegion.origin.x ..< tileRegion.origin.x + tileRegion.size.width {
                    let id = UUID().uuidString
                    delegate?.load(tile: Tile(x: x, y: y, id: id))
                    mapping[y][x] = id
                }
            }
        }
    }
}
