//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(_: BismushTextureDescriptor) -> (MTLTexture, MTLTexture?)
}

class BismushTexture {
    var context: BismushTextureContext
    struct Snapshot: Equatable, Hashable, Codable {
        var tiles: [TextureTileRegion: Blob]
    }

    var snapshot: Snapshot

    var renderPassDescriptior: MTLRenderPassDescriptor
    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
    let descriptor: BismushTextureDescriptor
    let mediator: TextureTileMediator
    let tileSize: MTLSize?
    let commandQueue: MTLCommandQueue

    var size: Size<TexturePixelCoordinate> {
        descriptor.size
    }

    convenience init(
        descriptor: BismushTextureDescriptor,
        context: BismushTextureContext
    ) {
        let (texture, msaaTexture) = context.createTexture(descriptor)
        self.init(
            texture: texture,
            msaaTexture: msaaTexture,
            loadAction: .clear,
            descriptor: descriptor,
            context: context
        )
    }

    init(
        texture: MTLTexture,
        msaaTexture: MTLTexture?,
        loadAction: MTLLoadAction,
        descriptor: BismushTextureDescriptor,
        context: BismushTextureContext
    ) {
        self.texture = texture
        self.msaaTexture = msaaTexture
        self.loadAction = loadAction
        self.descriptor = descriptor
        self.context = context
        let renderPassDescriptior = MTLRenderPassDescriptor()
        if let msaaTexture = msaaTexture {
            renderPassDescriptior.colorAttachments[0].texture = msaaTexture
            renderPassDescriptior.colorAttachments[0].resolveTexture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        } else {
            renderPassDescriptior.colorAttachments[0].texture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .store
        }
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        renderPassDescriptior.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)

        self.renderPassDescriptior = renderPassDescriptior
        snapshot = Snapshot(tiles: [:])

        commandQueue = context.device.metalDevice.makeCommandQueue()!

        if descriptor.tileSize != nil {
            tileSize = context.device.metalDevice.sparseTileSize(
                with: .type2D,
                pixelFormat: descriptor.pixelFormat,
                sampleCount: 1
            )
        } else {
            tileSize = nil
        }

        mediator = TextureTileMediator(descriptor: descriptor)
        mediator.delegate = self
        mediator.initialize(loadAction: loadAction)
    }

    func restore(from snapshot: Snapshot) {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            mediator.restore(tiles: snapshot.tiles, commandBuffer: commandBuffer)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        if !snapshot.tiles.isEmpty {
            loadAction = .load
        } else {
            loadAction = .clear
        }
    }

    func takeSnapshot() -> Snapshot {
        snapshot
    }

    func asRenderTarget(commandBuffer: MTLCommandBuffer, _ perform: (MTLRenderPassDescriptor) -> Void) {
        asRenderTarget(
            region: .init(x: 0, y: 0, width: size.width, height: size.height),
            commandBuffer: commandBuffer,
            perform
        )
    }

    func asRenderTarget(
        region: Rect<TexturePixelCoordinate>,
        commandBuffer: MTLCommandBuffer,
        _ perform: (MTLRenderPassDescriptor) -> Void
    ) {
        mediator.asRenderTarget(rect: region, commandBuffer: commandBuffer)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load
        perform(renderPassDescriptior)
    }
}

extension BismushTexture: TextureTileDelegate {
    func textureTileAllocate(region: TextureTileRegion, commandBuffer: MTLCommandBuffer) {
        guard let tileSize = tileSize else {
            return
        }
        guard let encoder = commandBuffer.makeResourceStateCommandEncoder() else {
            return
        }
        var region = MTLRegionMake2D(region.x, region.y, region.size.width, region.size.height)
        var tileRegion = MTLRegion()
        context.device.metalDevice.convertSparsePixelRegions?(
            &region,
            toTileRegions: &tileRegion,
            withTileSize: tileSize,
            alignmentMode: .outward,
            numRegions: 1
        )
        encoder.updateTextureMapping?(texture, mode: .map, region: tileRegion, mipLevel: 0, slice: 0)
        encoder.endEncoding()
    }

    func textureTileFree(region: TextureTileRegion, commandBuffer: MTLCommandBuffer) {
        guard let tileSize = tileSize else {
            return
        }
        guard let encoder = commandBuffer.makeResourceStateCommandEncoder() else {
            return
        }
        var region = MTLRegionMake2D(region.x, region.y, region.size.width, region.size.height)
        var tileRegion = MTLRegion()
        context.device.metalDevice.convertSparsePixelRegions?(
            &region,
            toTileRegions: &tileRegion,
            withTileSize: tileSize,
            alignmentMode: .outward,
            numRegions: 1
        )
        encoder.updateTextureMapping?(texture, mode: .unmap, region: tileRegion, mipLevel: 0, slice: 0)
        encoder.endEncoding()
    }

    func textureTileLoad(region: TextureTileRegion) -> Blob {
        let bytesPerRow = MemoryLayout<Float>.size * 4 * region.size.width
        let count = region.size.width * region.size.height * 4
        var bytes = [Float](repeating: 0, count: count)
        texture.getBytes(
            &bytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, region.size.width, region.size.height),
            mipmapLevel: 0
        )
        return Blob(data: NSData(bytes: bytes, length: 4 * count))
    }

    func textureTileStore(region: TextureTileRegion, blob: Blob) {
        let bytesPerRow = MemoryLayout<Float>.size * 4 * region.size.width
        (blob.data as Data).withUnsafeBytes { pointer in
            guard let baseAddress = pointer.baseAddress else {
                return
            }
            texture.replace(
                region: MTLRegionMake2D(0, 0, region.size.width, region.size.height),
                mipmapLevel: 0,
                withBytes: baseAddress,
                bytesPerRow: bytesPerRow
            )
        }
    }

    func textureTileSnapshot(tiles: [TextureTileRegion: Blob]) {
        snapshot = .init(tiles: tiles)
    }
}
