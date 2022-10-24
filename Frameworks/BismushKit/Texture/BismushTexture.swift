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
    let commandQueue: CommandQueue
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

        commandQueue = context.device.makeCommandQueue(label: #fileID)

        textureBuffer = context.device.makeBuffer(
            length: MemoryLayout<Float>.size * 4 * Int(descriptor.size.width) * Int(descriptor.size.height)
        )

        mediator = TextureTileMediator(descriptor: descriptor)
        mediator.delegate = self
        mediator.initialize(loadAction: loadAction)
    }

    func restore(from snapshot: Snapshot) {
        BismushLogger.texture.info("\(#function)")

        var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: #fileID)
        mediator.restore(tiles: snapshot.tiles, commandBuffer: commandBuffer)
        commandBuffer.commit()

        if !snapshot.tiles.isEmpty {
            loadAction = .load
        } else {
            loadAction = .clear
        }
    }

    func takeSnapshot() -> Snapshot {
        mediator.takeSnapshot()
        return snapshot
    }

    func asRenderTarget(commandBuffer: SequencialCommandBuffer,
                        useMSAA: Bool = true,
                        _ perform: (MTLRenderPassDescriptor) -> Void)
    {
        asRenderTarget(
            region: .init(x: 0, y: 0, width: size.width, height: size.height),
            commandBuffer: commandBuffer,
            useMSAA: useMSAA,
            perform
        )
    }

    func asRenderTarget(
        region: Rect<TexturePixelCoordinate>,
        commandBuffer: SequencialCommandBuffer,
        useMSAA: Bool = true,
        _ perform: (MTLRenderPassDescriptor) -> Void
    ) {
        BismushLogger.texture.trace("\(#function): \(region)")

        mediator.asRenderTarget(rect: region, commandBuffer: commandBuffer)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction

        if useMSAA, let msaaTexture = msaaTexture {
            renderPassDescriptior.colorAttachments[0].texture = msaaTexture
            renderPassDescriptior.colorAttachments[0].resolveTexture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        } else {
            renderPassDescriptior.colorAttachments[0].texture = texture
            renderPassDescriptior.colorAttachments[0].resolveTexture = nil
            renderPassDescriptior.colorAttachments[0].storeAction = .store
        }
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
        #if os(macOS) || targetEnvironment(macCatalyst)
            encoder.updateTextureMapping?(texture, mode: mode, region: tileRegion, mipLevel: 0, slice: 0)
        #else
            encoder.updateTextureMapping(texture, mode: mode, region: tileRegion, mipLevel: 0, slice: 0)
        #endif
    }

    func textureTileAllocate(regions: Set<TextureTileRegion>, commandBuffer: SequencialCommandBuffer) {
        commandBuffer.resourceState(label: #function) { encoder in
            for region in regions {
                BismushLogger.texture.info("\(#function): \(region))")
                updateTextureMapping(encoder: encoder, texture: texture, region: region, mode: .map)
                if let msaaTexture = msaaTexture {
                    updateTextureMapping(encoder: encoder, texture: msaaTexture, region: region, mode: .map)
                }
            }
        }
    }

    func textureTileFree(regions: Set<TextureTileRegion>, commandBuffer: SequencialCommandBuffer) {
        commandBuffer.resourceState(label: #function) { encoder in
            for region in regions {
                BismushLogger.texture.info("\(#function): \(region)")
                updateTextureMapping(encoder: encoder, texture: texture, region: region, mode: .unmap)
                if let msaaTexture = msaaTexture {
                    updateTextureMapping(encoder: encoder, texture: msaaTexture, region: region, mode: .unmap)
                }
            }
        }
    }

    func textureTileLoad(region: TextureTileRegion) -> Blob? {
        BismushLogger.texture.info("\(#function): \(region)")
        var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: "\(#function): \(region.description)")
        let bytesPerRow = MemoryLayout<Float>.size * 4 * region.size.width
        let bytesPerImage = bytesPerRow * region.size.height
        commandBuffer.blit(label: #function) { encoder in
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
        }
        commandBuffer.commit()

        return Blob(
            data: NSData(
                bytes: textureBuffer.contents(),
                length: bytesPerImage
            )
        )
    }

    func textureTileStore(region: TextureTileRegion, blob: Blob) {
        // FIXME: bulk update
        BismushLogger.texture.info("\(#function): \(region) \(blob.data.debugDescription)")
        guard !blob.data.isEmpty else {
            BismushLogger.texture.error("\(#function): blob is empty")
            return
        }

        var commandBuffer = commandQueue.makeSequencialCommandBuffer(label: #function)
        commandBuffer.blit(label: #function) { encoder in
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
        }
        commandBuffer.commit()
    }

    func textureTileSnapshot(tiles: [TextureTileRegion: Blob]) {
        BismushLogger.texture.info("\(#function): \(tiles.keys)")
        snapshot = .init(tiles: tiles)
    }
}
