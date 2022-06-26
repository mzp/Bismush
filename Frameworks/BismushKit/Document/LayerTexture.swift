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

class LayerTexture: Equatable {
    let canvasLayer: CanvasLayer
    private let context: LayerTextureContext
    private var isCopyOnWrite: Bool
    private var shouldClearOnNextRendering: Bool

    private(set) var texture: MTLTexture
    private(set) var msaaTexture: MTLTexture?

    private init(
        canvasLayer: CanvasLayer,
        context: LayerTextureContext,
        texture: MTLTexture,
        msaaTexture: MTLTexture?
    ) {
        self.canvasLayer = canvasLayer
        self.context = context
        self.texture = texture
        self.msaaTexture = msaaTexture
        shouldClearOnNextRendering = true
        isCopyOnWrite = false
    }

    init(canvasLayer: CanvasLayer, context: LayerTextureContext) {
        self.canvasLayer = canvasLayer
        self.context = context
        isCopyOnWrite = false

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
                BismushLogger.drawing.info("\(#function): Load texture data for \(canvasLayer.id)")
                texture.bmkData = data
                shouldClearOnNextRendering = false
            } else {
                shouldClearOnNextRendering = true
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
            shouldClearOnNextRendering = false
        }
    }

    var renderPassDescriptor: MTLRenderPassDescriptor {
        defer {
            // TOOD: property should not clear any state.
            self.shouldClearOnNextRendering = false
        }
        let renderPassDescriptior = MTLRenderPassDescriptor()
        if let msaaTexture = msaaTexture {
            renderPassDescriptior.colorAttachments[0].texture = msaaTexture
            renderPassDescriptior.colorAttachments[0].resolveTexture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        } else {
            renderPassDescriptior.colorAttachments[0].texture = texture
            renderPassDescriptior.colorAttachments[0].storeAction = .store
        }

        if shouldClearOnNextRendering {
            renderPassDescriptior.colorAttachments[0].loadAction = .clear
            renderPassDescriptior.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
            let id = canvasLayer.id
            BismushLogger.drawing.info("\(#function): Clear texture \(id)")
        } else {
            renderPassDescriptior.colorAttachments[0].loadAction = .load
        }
        return renderPassDescriptior
    }

    func makeWritable(commandBuffer: MTLCommandBuffer) {
        defer { isCopyOnWrite = false }
        guard isCopyOnWrite else {
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
    }

    // TODO: naming?
    func copyOnWrite() -> LayerTexture {
        if canvasLayer.layerType == .empty {
            isCopyOnWrite = true

            return .init(canvasLayer: canvasLayer, context: context, texture: texture, msaaTexture: msaaTexture)
        } else {
            return self
        }
    }

    static func == (lhs: LayerTexture, rhs: LayerTexture) -> Bool {
        lhs.texture.bmkData == rhs.texture.bmkData &&
            lhs.msaaTexture?.bmkData == rhs.msaaTexture?.bmkData
    }
}
