//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat) -> (MTLTexture, MTLTexture?)
}

class BismushTextureFactory: BismushTextureContext {
    let device: GPUDevice

    init(device: GPUDevice) {
        self.device = device
    }

    func create(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat) -> BismushTexture {
        .init(size: size, pixelFormat: pixelFormat, context: self)
    }
    func create(builtin name: String) -> BismushTexture {
        let texture = device.resource.bultinTexture(name: name)
        return .init(texture: texture, context: self)
    }

    func createTexture(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat) -> (MTLTexture, MTLTexture?) {
        BismushLogger.metal.info("Create Texture")
        let width = Int(size.width)
        let height = Int(size.height)

        let description = MTLTextureDescriptor()
        description.width = width
        description.height = height
        description.pixelFormat = pixelFormat
        description.usage = [.shaderRead, .renderTarget, .shaderWrite]
        description.textureType = .type2D

        let texture = device.metalDevice.makeTexture(descriptor: description)!

        if device.capability.msaa {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: pixelFormat,
                width: width,
                height: height,
                mipmapped: false
            )
            desc.textureType = .type2DMultisample
            desc.sampleCount = 4
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let msaaTexture = device.metalDevice.makeTexture(descriptor: desc)!
            return (texture, msaaTexture)
        } else {
            return (texture, nil)
        }
    }
}

extension CodingUserInfoKey {
    static let textureContext: CodingUserInfoKey = CodingUserInfoKey(rawValue: "jp.mzp.Bismush.textureContext")!
}


class BismushTexture {
    struct Snapshot: Codable, Equatable, Hashable {
        var size: Size<TextureCoordinate>
        var pixelFormat: MTLPixelFormat
        var data: Data
    }

    var snapshot: Snapshot
    var size: Size<TextureCoordinate> {
        snapshot.size
    }
    var pixelFormat: MTLPixelFormat {
        snapshot.pixelFormat
    }


    var context: BismushTextureContext

    init(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, context: BismushTextureContext) {
        let (texture, msaaTexture) = context.createTexture(size: size, pixelFormat: pixelFormat)
        self.texture = texture
        self.context = context
        self.msaaTexture = msaaTexture
        self.loadAction = .clear

        self.snapshot = .init(size: size, pixelFormat: pixelFormat, data: Data())
    }

    init(texture: MTLTexture, context: BismushTextureContext) {
        self.texture = texture
        self.loadAction = .load
        self.context = context
        self.snapshot = Snapshot(
            size: Size(width: Float(texture.width), height: Float(texture.height)),
            pixelFormat: texture.pixelFormat,
            data: texture.bmkData
        )
    }

    func restore(from snapshot: Snapshot) {
        assert(self.pixelFormat == snapshot.pixelFormat)
        assert(self.size == snapshot.size)
        self.snapshot = snapshot
        if snapshot.data.count > 0 {
            self.loadAction = .load
            self.texture.bmkData = snapshot.data
        } else {
            self.loadAction = .clear
        }
    }

    func takeSnapshot() -> Snapshot {
        return snapshot
    }

    func withRenderPassDescriptor(_ perform: (MTLRenderPassDescriptor) -> Void) {
        self.snapshot = .init(size: snapshot.size, pixelFormat: snapshot.pixelFormat, data: texture.bmkData)
        let renderPassDescriptior = MTLRenderPassDescriptor()
          if let msaaTexture = msaaTexture {
              renderPassDescriptior.colorAttachments[0].texture = msaaTexture
              renderPassDescriptior.colorAttachments[0].resolveTexture = texture
              renderPassDescriptior.colorAttachments[0].storeAction = .storeAndMultisampleResolve
          } else {
              renderPassDescriptior.colorAttachments[0].texture = texture
              renderPassDescriptior.colorAttachments[0].storeAction = .store
         }
        if loadAction == .clear {
            BismushLogger.metal.info("\(#function): clear")
        } else {
            BismushLogger.metal.info("\(#function): load")

        }
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        renderPassDescriptior.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.loadAction = .load
          perform(renderPassDescriptior)
      }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
