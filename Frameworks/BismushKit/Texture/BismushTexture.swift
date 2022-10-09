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
    let commandQueue: MTLCommandQueue
    let textureBuffer: MTLBuffer

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

        textureBuffer = context.device.metalDevice.makeBuffer(
            length: MemoryLayout<Float>.size * 4 * Int(descriptor.size.width) * Int(descriptor.size.height),
            options: .storageModeShared
        )!

        mediator = TextureTileMediator(descriptor: descriptor)
        mediator.delegate = self
        mediator.initialize(loadAction: loadAction)
    }

    func restore(from snapshot: Snapshot) {
        BismushLogger.texture.info("\(#function)")

        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "\(#function)"
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
    private func updateTextureMapping(
        encoder: MTLResourceStateCommandEncoder,
        texture: MTLTexture,
        region: TextureTileRegion,
        mode: MTLSparseTextureMappingMode
    ) {
        BismushLogger.texture.info("\(#function): \(region))")
        let tileSize = context.device.metalDevice.sparseTileSize(
            with: texture.textureType,
            pixelFormat: texture.pixelFormat,
            sampleCount: texture.sampleCount
        )
        var region = MTLRegionMake2D(region.x, region.y, region.size.width, region.size.height)
        var tileRegion = MTLRegion()
        context.device.metalDevice.convertSparsePixelRegions?(
            &region,
            toTileRegions: &tileRegion,
            withTileSize: tileSize,
            alignmentMode: .outward,
            numRegions: 1
        )
        encoder.updateTextureMapping?(texture, mode: mode, region: tileRegion, mipLevel: 0, slice: 0)
    }

    func textureTileAllocate(regions: Set<TextureTileRegion>, commandBuffer: MTLCommandBuffer) {
        BismushLogger.texture.info("\(#function): \(regions))")
        guard let encoder = commandBuffer.makeResourceStateCommandEncoder() else {
            return
        }
        for region in regions {
            updateTextureMapping(encoder: encoder, texture: texture, region: region, mode: .map)
            if let msaaTexture = msaaTexture {
                updateTextureMapping(encoder: encoder, texture: msaaTexture, region: region, mode: .map)
            }
        }
        encoder.endEncoding()
    }

    func textureTileFree(regions: Set<TextureTileRegion>, commandBuffer: MTLCommandBuffer) {
        BismushLogger.texture.info("\(#function): \(regions)")
        guard let encoder = commandBuffer.makeResourceStateCommandEncoder() else {
            return
        }
        for region in regions {
            updateTextureMapping(encoder: encoder, texture: texture, region: region, mode: .unmap)
            if let msaaTexture = msaaTexture {
                updateTextureMapping(encoder: encoder, texture: msaaTexture, region: region, mode: .unmap)
            }
        }
        encoder.endEncoding()
    }

    func textureTileLoad(region: TextureTileRegion) -> Blob? {
        BismushLogger.texture.info("\(#function): \(region)")
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }
        guard let encoder = commandBuffer.makeBlitCommandEncoder() else {
            return nil
        }
        commandBuffer.label = "\(#function)"

        let bytesPerRow = MemoryLayout<Float>.size * 4 * region.size.width
        let bytesPerImage = bytesPerRow * region.size.height
        encoder.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: region.x, y: region.y, z: 0),
            sourceSize: MTLSize(width: region.size.width, height: region.size.height, depth: 1),
            to: textureBuffer,
            destinationOffset: 0,
            destinationBytesPerRow: bytesPerRow,
            destinationBytesPerImage: bytesPerImage
        )

        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return Blob(
            data: NSData(
                bytes: textureBuffer.contents(),
                length: bytesPerImage
            )
        )
    }

    func textureTileStore(region: TextureTileRegion, blob: Blob) {
        BismushLogger.texture.info("\(#function): \(region) \(blob.data.debugDescription)")
        guard !blob.data.isEmpty else {
            BismushLogger.texture.error("\(#function): blob is empty")
            return
        }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        guard let encoder = commandBuffer.makeBlitCommandEncoder() else {
            return
        }
        commandBuffer.label = "\(#function)"
        let bytesPerRow = MemoryLayout<Float>.size * 4 * region.size.width
        let bytesPerImage = bytesPerRow * region.size.height

        (blob.data as Data).withUnsafeBytes { pointer in
            guard let baseAddress = pointer.baseAddress else {
                return
            }
            textureBuffer.contents().copyMemory(
                from: baseAddress,
                byteCount: bytesPerImage
            )
        }
        encoder.copy(
            from: textureBuffer,
            sourceOffset: 0,
            sourceBytesPerRow: bytesPerRow,
            sourceBytesPerImage: bytesPerImage,
            sourceSize: MTLSize(width: region.size.width, height: region.size.height, depth: 1),
            to: texture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: region.x, y: region.y, z: 0)
        )
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func textureTileSnapshot(tiles: [TextureTileRegion: Blob]) {
        BismushLogger.texture.info("\(#function): \(tiles.keys)")
        snapshot = .init(tiles: tiles)
    }
}
