//
//  File.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/28/22.
//

import Foundation
import Metal

struct Tile: Codable, Hashable, Equatable {
    var region: Rect<TexturePixelCoordinate>
    var blob: Blob?
}

class TileList {
    private let texture: MTLTexture
    var tiles: [Tile] {
        get {
            regions.map { region in
                let width = Int(region.size.width)
                let height = Int(region.size.height)
                let bytesPerRow = MemoryLayout<Float>.size * 4 * width
                let count = width * height * 4
                var bytes = [Float](repeating: 0, count: count)
                texture.getBytes(
                    &bytes,
                    bytesPerRow: bytesPerRow,
                    from: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0
                )
                let data = Data(bytes: bytes, count: 4 * count)
                return Tile(region: region, blob: Blob(data: data as NSData))
            }
        }
        set {
            regions = newValue.map(\.region)
        }
    }

    var regions: [Rect<TexturePixelCoordinate>]

    init(texture: MTLTexture, tiles: [Tile]) {
        self.texture = texture
        regions = tiles.map(\.region)
    }

    func load<T: Sequence>(points _: T) where T.Element == Point<TextureCoordinate> {
        // update tiles with empty data
        // update region
        /*
         let encoder = commandBuffer.makeResourceStateCommandEncoder()!
         for region in unloadRegions {
             encoder.updateTextureMapping?(texture, mode: .map, region: region, mipLevel: 0, slice: 0)
         }
         encoder.endEncoding()

         */
        /*
         //
         //  MTLTexture+Data.swift
         //  Bismush
         //
         //  Created by mzp on 6/20/22.
         //

         import Foundation
         import Metal

         extension MTLTexture {
             var bmkData: Data {
                 get {
                     let bytesPerRow = MemoryLayout<Float>.size * 4 * width
                     let count = width * height * 4
                     var bytes = [Float](repeating: 0, count: count)
                     getBytes(
                         &bytes,
                         bytesPerRow: bytesPerRow,
                         from: MTLRegionMake2D(0, 0, width, height),
                         mipmapLevel: 0
                     )
                     return Data(bytes: bytes, count: 4 * count)
                 }
                 set {
                     let bytesPerRow = MemoryLayout<Float>.size * 4 * width
                     newValue.withUnsafeBytes { pointer in
                         guard let baseAddress = pointer.baseAddress else {
                             return
                         }
                         replace(
                             region: MTLRegionMake2D(0, 0, width, height),
                             mipmapLevel: 0,
                             withBytes: baseAddress,
                             bytesPerRow: bytesPerRow
                         )
                     }
                 }
             }
         }

         */
    }
}
