//
//  Texture.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

import Metal

protocol LayerTextureContext {
    var device: GPUDevice { get }
    func layer(id: String, type: String) -> Data?
}

class LayerTexture {
    enum State {
        case clean
        case uninitialized
        case copyOnWrite
    }

    let canvasLayer: CanvasLayer
    private let context: LayerTextureContext
    private var state: State

    private(set) var texture: MTLTexture
    private(set) var msaaTexture: MTLTexture?

    private init(canvasLayer: CanvasLayer, context: LayerTextureContext, texture: MTLTexture, msaaTexture: MTLTexture?) {
        self.canvasLayer = canvasLayer
        self.context = context
        self.texture = texture
        self.msaaTexture = msaaTexture
        state = .clean
    }

    init(canvasLayer: CanvasLayer, context: LayerTextureContext) {
        self.canvasLayer = canvasLayer
        self.context = context

        switch canvasLayer.layerType {
        case .empty:
            let size = canvasLayer.size
            let width = Int(size.width)
            let height = Int(size.height)

            let description = MTLTextureDescriptor()
            description.width = width
            description.height = height
            description.pixelFormat = canvasLayer.pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D

            let texture = context.device.metalDevice.makeTexture(descriptor: description)!

            if let data = context.layer(id: canvasLayer.id, type: "texture") {
                texture.bmkData = data
                state = .clean
            } else {
                state = .uninitialized
            }
            self.texture = texture

            if context.device.capability.msaa {
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: canvasLayer.pixelFormat,
                    width: width,
                    height: height,
                    mipmapped: false
                )
                desc.textureType = .type2DMultisample
                desc.sampleCount = 4
                desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
                let msaaTexture = context.device.metalDevice.makeTexture(descriptor: desc)!

                if let data = context.layer(id: canvasLayer.id, type: "msaatexture") {
                    msaaTexture.bmkData = data
                }
                self.msaaTexture = msaaTexture
            } else {
                msaaTexture = nil
            }
        case let .builtin(name: name):
            texture = context.device.resource.bultinTexture(name: name)
            state = .clean
        }
    }

    var renderPassDescriptor: MTLRenderPassDescriptor {
        let renderPassDescriptior = MTLRenderPassDescriptor()
        if let msaaTexture = msaaTexture {
            renderPassDescriptior.colorAttachments[0].texture = msaaTexture
            renderPassDescriptior.colorAttachments[0].resolveTexture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        } else {
            renderPassDescriptior.colorAttachments[0].texture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .store
        }

        renderPassDescriptior.colorAttachments[0].loadAction = state == .uninitialized ? .clear : .load
        renderPassDescriptior.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        return renderPassDescriptior
    }

    func makeWritable(commandBuffer: MTLCommandBuffer) {
        guard state == .copyOnWrite else {
            return
        }

        if let encoder = commandBuffer.makeBlitCommandEncoder() {
            let description = MTLTextureDescriptor()
            description.width = Int(canvasLayer.size.width)
            description.height = Int(canvasLayer.size.height)
            description.pixelFormat = canvasLayer.pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D
            let newTexture = context.device.metalDevice.makeTexture(descriptor: description)!
            encoder.copy(from: texture, to: newTexture)
            texture = newTexture

            if let msaaTexture = msaaTexture {
                description.textureType = .type2DMultisample
                description.sampleCount = 4
                let newMsaaTexture = context.device.metalDevice.makeTexture(descriptor: description)!
                encoder.copy(from: msaaTexture, to: newMsaaTexture)
                self.msaaTexture = newMsaaTexture
            }
            encoder.endEncoding()
        }
        state = .clean
    }

    func copyOnWrite() -> LayerTexture {
        if canvasLayer.layerType == .empty {
            state = .copyOnWrite

            return .init(canvasLayer: canvasLayer, context: context, texture: texture, msaaTexture: msaaTexture)
        } else {
            return self
        }
    }
}
