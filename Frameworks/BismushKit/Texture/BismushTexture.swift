//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(_: BismushTextureDescriptior) -> (MTLTexture, MTLTexture?)
}

class BismushTexture {
    struct Snapshot: Equatable, Hashable, Codable {
        var tiles: [Tile]
    }

    var snapshot: Snapshot
    var context: BismushTextureContext
    var renderPassDescriptior: MTLRenderPassDescriptor
    var tileList: TileList

    let descriptor: BismushTextureDescriptior

    var size: Size<TexturePixelCoordinate> {
        descriptor.size
    }

    convenience init(
        descriptor: BismushTextureDescriptior,
        context: BismushTextureContext
    ) {
        let (texture, msaaTexture) = context.createTexture(descriptor)
        self.init(
            texture: texture,
            msaaTexture: msaaTexture,
            tileList: TileList(texture: texture, tiles: []),
            loadAction: .clear,
            descriptor: descriptor,
            context: context
        )
    }

    init(
        texture: MTLTexture,
        msaaTexture: MTLTexture?,
        tileList: TileList,
        loadAction: MTLLoadAction,
        descriptor: BismushTextureDescriptior,
        context: BismushTextureContext
    ) {
        self.texture = texture
        self.msaaTexture = msaaTexture
        self.loadAction = loadAction
        self.descriptor = descriptor
        self.context = context
        self.tileList = tileList

        snapshot = Snapshot(
            tiles: tileList.tiles
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
        if !snapshot.tiles.isEmpty {
            loadAction = .load
            tileList.tiles = snapshot.tiles
//            texture.bmkData = snapshot.data
        } else {
            loadAction = .clear
        }
    }

    func takeSnapshot() -> Snapshot {
        snapshot
    }

    func withRenderPassDescriptor(commandBuffer _: MTLCommandBuffer, _ perform: (MTLRenderPassDescriptor) -> Void) {
        snapshot = .init(tiles: tileList.tiles)

        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load
        perform(renderPassDescriptior)
    }

//    var unloadRegions = [MTLRegion]()

    func load<T: Sequence>(points: T) where T.Element == Point<TextureCoordinate> {
        tileList.load(points: points)
    }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
