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

    func create(snapshot: BismushTexture.Snapshot) -> BismushTexture {
        BismushTexture(from: snapshot, context: self)
    }

    func createTexture(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat) -> (MTLTexture, MTLTexture?) {
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


struct BismushTexture {
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
        self.init(from: .init(size: size, pixelFormat: pixelFormat, data: Data()),
                  context: context)
    }

    init(from snapshot: Snapshot, context: BismushTextureContext) {
        self.snapshot = snapshot
        self.context = context

        let (texture, msaaTexture) = context.createTexture(size: snapshot.size, pixelFormat: snapshot.pixelFormat)
        if snapshot.data.count > 0 {
            self.loadAction = .load
            texture.bmkData = snapshot.data
        } else {
            self.loadAction = .clear
        }


        self.texture = texture
        self.msaaTexture = msaaTexture
    }

    mutating func takeSnapshot() -> Snapshot {
        return snapshot
    }

    mutating func withRenderPassDescriptor(_ perform: (MTLRenderPassDescriptor) -> Void) {
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
          perform(renderPassDescriptior)
      }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
