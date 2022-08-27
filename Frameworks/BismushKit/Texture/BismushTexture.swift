//
//  BismushTexture.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import Foundation

protocol BismushTextureContext {
    var device: GPUDevice { get }
    func createTexture(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, rasterSampleCount: Int) -> (MTLTexture, MTLTexture?)
}

class BismushTextureFactory: BismushTextureContext {
    let device: GPUDevice

    init(device: GPUDevice) {
        self.device = device
    }

    func create(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, rasterSampleCount: Int) -> BismushTexture {
        .init(size: size, pixelFormat: pixelFormat, rasterSampleCount: rasterSampleCount, context: self)
    }

    func create(builtin name: String) -> BismushTexture {
        let texture = device.resource.bultinTexture(name: name)
        return .init(texture: texture, msaaTexture: nil, loadAction: .load, rasterSampleCount: 1, context: self)
    }

    func createTexture(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, rasterSampleCount: Int) -> (MTLTexture, MTLTexture?) {
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

        if rasterSampleCount > 1 {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: pixelFormat,
                width: width,
                height: height,
                mipmapped: false
            )
            desc.textureType = .type2DMultisample
            desc.sampleCount = rasterSampleCount
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let msaaTexture = device.metalDevice.makeTexture(descriptor: desc)!
            return (texture, msaaTexture)
        } else {
            return (texture, nil)
        }
    }
}

extension CodingUserInfoKey {
    static let textureContext: CodingUserInfoKey = .init(rawValue: "jp.mzp.Bismush.textureContext")!
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

    convenience init(size: Size<TextureCoordinate>, pixelFormat: MTLPixelFormat, rasterSampleCount: Int, context: BismushTextureContext) {
        let (texture, msaaTexture) = context.createTexture(size: size, pixelFormat: pixelFormat, rasterSampleCount: rasterSampleCount)
        self.init(texture: texture, msaaTexture: msaaTexture, loadAction: .clear, rasterSampleCount: rasterSampleCount, context: context)
    }

    init(texture: MTLTexture, msaaTexture: MTLTexture?, loadAction: MTLLoadAction, rasterSampleCount: Int, context: BismushTextureContext) {
        self.texture = texture
        self.msaaTexture = msaaTexture
        self.loadAction = loadAction
        self.rasterSampleCount = rasterSampleCount
        self.context = context
        snapshot = Snapshot(
            size: Size(width: Float(texture.width), height: Float(texture.height)),
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

    func withRenderPassDescriptor(_ perform: (MTLRenderPassDescriptor) -> Void) {
        snapshot = .init(size: snapshot.size, pixelFormat: snapshot.pixelFormat, data: texture.bmkData)
        renderPassDescriptior.colorAttachments[0].loadAction = loadAction
        loadAction = .load
        perform(renderPassDescriptior)
    }

    var loadAction: MTLLoadAction
    var texture: MTLTexture
    var msaaTexture: MTLTexture?
}
