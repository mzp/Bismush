//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(_: TextureDescriptior) -> (MTLTexture, MTLTexture?)
}

class BismushTexture {
    struct Snapshot: Equatable, Hashable, Codable {
        var nsData: NSData

        var data: Data {
            get { nsData as Data }
            set { nsData = newValue as NSData }
        }

        init(data nsData: NSData) {
            self.nsData = nsData
        }

        init(data: Data) {
            nsData = data as NSData
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            nsData = try container.decode(Data.self) as NSData
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(nsData as Data)
        }
    }

    var snapshot: Snapshot
    var context: BismushTextureContext
    var renderPassDescriptior: MTLRenderPassDescriptor
    var map: SparseTextureMap?

    let descriptor: TextureDescriptior

    var size: Size<TexturePixelCoordinate> {
        descriptor.size
    }

    convenience init(
        descriptor: TextureDescriptior,
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
        descriptor: TextureDescriptior,
        context: BismushTextureContext
    ) {
        self.texture = texture
        self.msaaTexture = msaaTexture
        self.loadAction = loadAction
        self.descriptor = descriptor
        self.context = context

        snapshot = Snapshot(
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
        snapshot = .init(data: texture.bmkData)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load

        if !unloadRegions.isEmpty {
            let encoder = commandBuffer.makeResourceStateCommandEncoder()!
            for region in unloadRegions {
                encoder.updateTextureMapping?(texture, mode: .map, region: region, mipLevel: 0, slice: 0)
            }
            encoder.endEncoding()
            unloadRegions.removeAll()
        }

        perform(renderPassDescriptior)
    }

    var unloadRegions = [MTLRegion]()

    func load<T: Sequence>(points: T) where T.Element == Point<TextureCoordinate> {
        guard let region = map?.unmappingRegion(for: points) else {
            return
        }
        unloadRegions.append(region)
        map?.updateMapping(region: region)
    }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
