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
    func textureTileAllocate(regions: Set<TextureTileRegion>, commandBuffer: SequencialCommandBuffer)
    func textureTileFree(regions: Set<TextureTileRegion>, commandBuffer: SequencialCommandBuffer)

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
    private var tiles: [TextureTileRegion: Blob]?

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

    func restore(tiles: [TextureTileRegion: Blob], commandBuffer: SequencialCommandBuffer) {
        self.tiles = tiles
        if descriptor.tileSize != nil {
            let freeRegions = regions.subtracting(tiles.keys)
            let newRegions = Set(tiles.keys).subtracting(regions)

            if !freeRegions.isEmpty {
                delegate?.textureTileFree(
                    regions: freeRegions,
                    commandBuffer: commandBuffer
                )
            }
            if !newRegions.isEmpty {
                delegate?.textureTileAllocate(
                    regions: newRegions,
                    commandBuffer: commandBuffer
                )
            }
            regions = Set(tiles.keys)
        }

        for (region, blob) in tiles {
            delegate?.textureTileStore(region: region, blob: blob)
        }
    }

    func takeSnapshot() {
        if let tiles = tiles {
            delegate?.textureTileSnapshot(tiles: tiles)
        } else {
            if descriptor.tileSize != nil {
                var tiles = [TextureTileRegion: Blob]()
                for region in regions {
                    if let blob = delegate?.textureTileLoad(region: region) {
                        tiles[region] = blob
                    }
                }
                delegate?.textureTileSnapshot(tiles: tiles)
                self.tiles = tiles
            } else {
                let region = TextureTileRegion(x: 0, y: 0, width: width, height: height)
                if let blob = delegate?.textureTileLoad(region: region) {
                    let tiles = [region: blob]
                    delegate?.textureTileSnapshot(tiles: tiles)
                    self.tiles = tiles
                }
            }
        }
    }

    func asRenderTarget(rect: Rect<TexturePixelCoordinate>, commandBuffer: SequencialCommandBuffer) {
        tiles = nil
        if let tileSize = descriptor.tileSize {
            // allocate memory
            let newRegions = Rect(
                origin: .zero(),
                size: descriptor.size
            ).split(
                cover: rect,
                tileSize: tileSize
            ).subtracting(
                regions
            )
            if !newRegions.isEmpty {
                delegate?.textureTileAllocate(
                    regions: newRegions,
                    commandBuffer: commandBuffer
                )
                for newRegion in newRegions {
                    regions.insert(newRegion)
                }
            }
        }
    }
}
