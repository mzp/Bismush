//
//  SparseTextureMap.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

// https://developer.apple.com/documentation/metal/textures/assigning_memory_to_sparse_textures
// https://developer.apple.com/documentation/metal/textures/reading_and_writing_to_sparse_textures

import Foundation

struct SparseTextureMap {
    var device: GPUDevice
    var size: Size<TextureCoordinate>
    var tileSize: MTLSize
    var tileSizeInFloat: Size<TextureCoordinate>
    var mapping: [[MTLSparseTextureMappingMode]]

    init(device: GPUDevice,
         size: Size<TextureCoordinate>,
         tileSize: MTLSize)
    {
        self.device = device
        self.size = size
        self.tileSize = tileSize
        tileSizeInFloat = Size(width: Float(tileSize.width), height: Float(tileSize.height))

        let regionSize = size.rawValue / SIMD2(Float(tileSize.width), Float(tileSize.height)).rounded(.up)
        mapping = Array(
            repeating: Array(
                repeating: .unmap,
                count: Int(regionSize.x)
            ),
            count: Int(regionSize.y)
        )
    }

    func unmappingRegion<T: Sequence>(for points: T) -> MTLRegion? where T.Element == Point<TextureCoordinate> {
        var minX = Int.max
        var minY = Int.max
        var maxX = 0
        var maxY = 0

        for point in points {
            let tile = (point.rawValue / tileSizeInFloat.rawValue).rounded(.up)

            let x = Int(point.x)
            let y = Int(point.y)

            if mapping[Int(tile.y)][Int(tile.x)] == .unmap {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        if minX == Int.max, minY == Int.max {
            return nil
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
            device.metalDevice.convertSparsePixelRegions?(
                &pixelRegion,
                toTileRegions: &tileRegion,
                withTileSize: tileSize,
                alignmentMode: .outward,
                numRegions: 1
            )
            return tileRegion
        }
    }

    mutating func updateMapping(region: MTLRegion) {
        for y in region.origin.y ..< region.origin.y + region.size.height {
            for x in region.origin.x ..< region.origin.x + region.size.width {
                mapping[y][x] = .map
            }
        }
    }
}
