//
//  TextureTile.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/28/22.
//

import Foundation
import Metal

protocol TextureTileDelegate: AnyObject {
    // update memory mapping
    func textureTileAllocate(region: TextureTileRegion, commandBuffer: MTLCommandBuffer)
    func textureTileFree(region: TextureTileRegion, commandBuffer: MTLCommandBuffer)

    // load data from texture
    func textureTileLoad(region: TextureTileRegion) -> Blob?

    // write data to texture
    func textureTileStore(region: TextureTileRegion, blob: Blob)

    // register undo buffer
    func textureTileSnapshot(tiles: [TextureTileRegion: Blob])
}

class TextureTileMediator {
    private let descriptor: BismushTextureDescriptor
    private var regions: Set<TextureTileRegion>

    private var width: Int {
        Int(descriptor.size.width)
    }

    private var height: Int {
        Int(descriptor.size.height)
    }

    weak var delegate: TextureTileDelegate?

    init(descriptor: BismushTextureDescriptor) {
        self.descriptor = descriptor
        regions = Set()
    }

    func initialize(loadAction: MTLLoadAction) {
        guard loadAction == .load else {
            return
        }
        let region = TextureTileRegion(
            x: 0,
            y: 0,
            width: width,
            height: height
        )
        if let blob = delegate?.textureTileLoad(region: region) {
            delegate?.textureTileSnapshot(tiles: [region: blob])
        }
    }

    func restore(tiles: [TextureTileRegion: Blob], commandBuffer: MTLCommandBuffer) {
        if descriptor.tileSize != nil {
            for region in regions.subtracting(tiles.keys) {
                delegate?.textureTileFree(region: region, commandBuffer: commandBuffer)
                regions.remove(region)
            }
            for region in Set(tiles.keys).subtracting(regions) {
                delegate?.textureTileAllocate(region: region, commandBuffer: commandBuffer)
                regions.insert(region)
            }
        }

        for (region, blob) in tiles {
            delegate?.textureTileStore(region: region, blob: blob)
        }
    }

    func asRenderTarget(rect: Rect<TexturePixelCoordinate>, commandBuffer: MTLCommandBuffer) {
        if let tileSize = descriptor.tileSize {
            // take snapshot
            var snapshot = [TextureTileRegion: Blob]()
            for region in regions {
                if let blob = delegate?.textureTileLoad(region: region) {
                    snapshot[region] = blob
                }
            }
            delegate?.textureTileSnapshot(tiles: snapshot)

            // allocate memory
            let tiles = Rect(
                origin: .zero(),
                size: descriptor.size
            ).split(
                cover: rect,
                tileSize: tileSize
            )
            for tile in tiles {
                delegate?.textureTileAllocate(region: tile, commandBuffer: commandBuffer)
                regions.insert(tile)
            }
        } else {
            let region = TextureTileRegion(x: 0, y: 0, width: width, height: height)
            if let blob = delegate?.textureTileLoad(region: region) {
                delegate?.textureTileSnapshot(tiles: [region: blob])
            }
        }
    }
}
