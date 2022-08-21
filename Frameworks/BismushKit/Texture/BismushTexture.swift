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
        return .init(context: self, source: .empty(size: size, pixelFormat: pixelFormat))
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


struct BismushTexture: Codable /*: Equatable, Codable*/ {
    enum TextureSource {
        case empty(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat)
        indirect case refer(to: BismushTexture)
        indirect case copy(from: BismushTexture)
    }
    var context: BismushTextureContext
    var source: TextureSource?
    var size: Size<TextureCoordinate>
    var pixelFormat: MTLPixelFormat

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?

    init(
        context : BismushTextureContext,
        source: TextureSource
    ) {
        self.context = context
        self.source = source

        switch source {
        case let .empty(size: size, pixelFormat: pixelFormat):
            self.loadAction = .clear
            let (texture, msaaTexture) = context.createTexture(size: size, pixelFormat: pixelFormat)
            self.texture = texture
            self.msaaTexture = msaaTexture
            self.size = size
            self.pixelFormat = pixelFormat
        case let .refer(to: texture):
            self.loadAction = .load
            self.texture = texture.texture
            self.msaaTexture = texture.msaaTexture
            self.size = texture.size
            self.pixelFormat = texture.pixelFormat
        case let .copy(from: texture):
            self.loadAction = .load
            self.size = texture.size
            self.pixelFormat = texture.pixelFormat

            let (metalTexture, msaaTexture) = context.createTexture(size: texture.size, pixelFormat: texture.pixelFormat)

            // TODO: copy tile
            metalTexture.bmkData = texture.texture.bmkData
            self.texture = metalTexture
            self.msaaTexture = msaaTexture
        }
    }

    init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.textureContext] as? BismushTextureContext else {
            throw InvalidContextError()
        }
        var container = try decoder.unkeyedContainer()
        let size = try container.decode(Size<TextureCoordinate>.self)
        let pixelFormat = try container.decode(MTLPixelFormat.self)
        let data = try container.decode(Data.self)

        self.context = context
        self.loadAction = .load
        self.size = size
        self.pixelFormat = pixelFormat
        let (texture, msaaTexture) = context.createTexture(size: size, pixelFormat: pixelFormat)

        self.texture = texture
        self.msaaTexture = msaaTexture

        texture.bmkData = data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(size)
        try container.encode(pixelFormat)
        try container.encode(texture.bmkData)
    }


    mutating func withRenderPassDescriptor(perform: (MTLRenderPassDescriptor) -> Void) {
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

    func copy() -> BismushTexture {
        return BismushTexture(context: context, source: .refer(to: self))
    }

    func mutable() -> BismushTexture {
        return BismushTexture(context: context, source: .copy(from: self))
    }

}
