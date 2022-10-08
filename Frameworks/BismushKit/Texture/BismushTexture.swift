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
    struct Snapshot: Equatable, Hashable, Codable {
        var tiles: [TextureTileRegion: Blob]
    }

    var snapshot: Snapshot
    var context: BismushTextureContext
    var renderPassDescriptior: MTLRenderPassDescriptor

    let descriptor: BismushTextureDescriptor

    let mediator: TextureTileMediator

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
        mediator = TextureTileMediator(descriptor: descriptor)

        // TODO: non sparseならここでsnapshotをとりたい
        snapshot = Snapshot(
            tiles: [:]
        )
        mediator.initialize(loadAction: loadAction)
    }

    func restore(from snapshot: Snapshot) {
        self.snapshot = snapshot
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
        /*        if let tileSize = descriptor.tileSize {

         }*/
        // TODO: 今の状態のsnapshotをとる
        // TODO: レンダリングする前にregionにメモリを割り当てる
//        snapshot = .init(tiles: tileList.tiles)
        mediator.asRenderTarget(rect: region, commandBuffer: commandBuffer)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load
        perform(renderPassDescriptior)
    }

    func load(
        region _: Rect<TexturePixelCoordinate>,
        commandBuffer _: MTLCommandBuffer
    ) {
        // TODO: このテクスチャを使うのでregionの範囲をsnapshotから読み取る
        /*        guard descriptor.tileSize else {
             return
         }*/
    }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
