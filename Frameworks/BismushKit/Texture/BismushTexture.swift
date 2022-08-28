//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(
        size: Size<TextureCoordinate>,
        pixelFormat: MTLPixelFormat,
        rasterSampleCount: Int
    ) -> (MTLTexture, MTLTexture?)
}

class BismushTexture {
    struct Snapshot: Equatable, Hashable, Codable {
        var size: Size<TextureCoordinate>
        var pixelFormat: MTLPixelFormat
        var nsData: NSData

        var data: Data {
            get { nsData as Data }
            set { nsData = newValue as NSData }
        }

        init(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, data nsData: NSData) {
            self.size = size
            self.pixelFormat = pixelFormat
            self.nsData = nsData
        }

        init(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, data: Data) {
            self.size = size
            self.pixelFormat = pixelFormat
            nsData = data as NSData
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            size = try container.decode(Size<TextureCoordinate>.self)
            pixelFormat = try container.decode(MTLPixelFormat.self)
            nsData = try container.decode(Data.self) as NSData
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(size)
            try container.encode(pixelFormat)
            try container.encode(nsData as Data)
        }
    }

    var snapshot: Snapshot
    var size: Size<TextureCoordinate> {
        snapshot.size
    }

    var pixelFormat: MTLPixelFormat {
        snapshot.pixelFormat
    }

    var rasterSampleCount: Int

    var context: BismushTextureContext
    var renderPassDescriptior: MTLRenderPassDescriptor
    var map: SparseTextureMap

    convenience init(
        size: Size<TextureCoordinate>,
        pixelFormat: MTLPixelFormat,
        rasterSampleCount: Int,
        context: BismushTextureContext
    ) {
        let (texture, msaaTexture) = context.createTexture(
            size: size,
            pixelFormat: pixelFormat,
            rasterSampleCount: rasterSampleCount,
            sparse: Bool
        )
        self.init(
            texture: texture,
            msaaTexture: msaaTexture,
            loadAction: .clear,
            rasterSampleCount: rasterSampleCount,
            context: context,
            sparse: sparse
        )
    }

    init(
        texture: MTLTexture,
        msaaTexture: MTLTexture?,
        loadAction: MTLLoadAction,
        rasterSampleCount: Int,
        context: BismushTextureContext,
        sparse _: Bool
    ) {
        self.texture = texture
        self.msaaTexture = msaaTexture
        self.loadAction = loadAction
        self.rasterSampleCount = rasterSampleCount
        self.context = context
        let size = Size<TextureCoordinate>(width: Float(texture.width), height: Float(texture.height))

        map = SparseTextureMap(
            device: context.device,
            size: size,
            tileSize: context.device.metalDevice.sparseTileSize(
                with: .type2D,
                pixelFormat:
                texture.pixelFormat,
                sampleCount: rasterSampleCount
            )
        )
        snapshot = Snapshot(
            size: size,
            pixelFormat: texture.pixelFormat,
            data: texture.bmkData
        )

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
    }

    func restore(from snapshot: Snapshot) {
        assert(pixelFormat == snapshot.pixelFormat)
        assert(size == snapshot.size)
        self.snapshot = snapshot
        if !snapshot.data.isEmpty {
            loadAction = .load
            texture.bmkData = snapshot.data
        } else {
            loadAction = .clear
        }
    }

    func takeSnapshot() -> Snapshot {
        snapshot
    }

    func withRenderPassDescriptor(commandBuffer: MTLCommandBuffer, _ perform: (MTLRenderPassDescriptor) -> Void) {
        snapshot = .init(size: snapshot.size, pixelFormat: snapshot.pixelFormat, data: texture.bmkData)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load

        if !unloadRegions.isEmpty {
            let encoder = commandBuffer.makeResourceStateCommandEncoder()!
            for region in unloadRegions {
                encoder.updateTextureMapping(texture, mode: .map, region: region, mipLevel: 0, slice: 0)
            }
            encoder.endEncoding()
            unloadRegions.removeAll()
        }

        perform(renderPassDescriptior)
    }

    var unloadRegions = [MTLRegion]()

    func load<T: Sequence>(points: T) where T.Element == Point<TextureCoordinate> {
        guard let region = map.unmappingRegion(for: points) else {
            return
        }
        unloadRegions.append(region)
        map.updateMapping(region: region)
    }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
