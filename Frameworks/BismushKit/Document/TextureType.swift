//
//  Texture.swift
//  Bismush
//
//  Created by mzp on 6/20/22.
//

import Metal

protocol TextureType {
    var texture: MTLTexture { get }
    var size: Size<TextureCoordinate> { get }
}

protocol TextureContext {
    var device: GPUDevice { get }
    func layer(id: String, type: String) -> Data?
}

class Texture: TextureType, Equatable {
    let pixelFormat: MTLPixelFormat
    let size: Size<TextureCoordinate>
    let context: TextureContext
    fileprivate(set) var texture: MTLTexture
    fileprivate(set) var msaaTexture: MTLTexture?

    init(
        pixelFormat: MTLPixelFormat,
        size: Size<TextureCoordinate>,
        context: TextureContext,
        texture: MTLTexture,
        msaaTexture: MTLTexture?
    ) {
        self.pixelFormat = pixelFormat
        self.size = size
        self.context = context
        self.texture = texture
        self.msaaTexture = msaaTexture
    }

    init(pixelFormat: MTLPixelFormat, size: Size<TextureCoordinate>, context: TextureContext) {
        self.pixelFormat = pixelFormat
        self.size = size
        self.context = context

        let width = Int(size.width)
        let height = Int(size.height)

        let description = MTLTextureDescriptor()
        description.width = width
        description.height = height
        description.pixelFormat = pixelFormat
        description.usage = [.shaderRead, .renderTarget, .shaderWrite]
        description.textureType = .type2D

        let texture = context.device.metalDevice.makeTexture(descriptor: description)!
        self.texture = texture

        if context.device.capability.msaa {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: pixelFormat,
                width: width,
                height: height,
                mipmapped: false
            )
            desc.textureType = .type2DMultisample
            desc.sampleCount = 4
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let msaaTexture = context.device.metalDevice.makeTexture(descriptor: desc)!
            self.msaaTexture = msaaTexture
        } else {
            msaaTexture = nil
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
        return renderPassDescriptior
    }

    func makeWritable(commandBuffer: MTLCommandBuffer) {
        if let encoder = commandBuffer.makeBlitCommandEncoder() {
            let description = MTLTextureDescriptor()
            description.width = Int(size.width)
            description.height = Int(size.height)
            description.pixelFormat = pixelFormat
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

    static func == (lhs: Texture, rhs: Texture) -> Bool {
        lhs.texture.bmkData == rhs.texture.bmkData &&
            lhs.msaaTexture?.bmkData == rhs.msaaTexture?.bmkData
    }
}

class LayerTexture: Texture {
    let canvasLayer: CanvasLayer
    private var isCopyOnWrite: Bool
    private var shouldClearOnNextRendering: Bool

    private init(
        canvasLayer: CanvasLayer,
        context: TextureContext,
        texture: MTLTexture,
        msaaTexture: MTLTexture?
    ) {
        self.canvasLayer = canvasLayer
        shouldClearOnNextRendering = true
        isCopyOnWrite = false
        super.init(
            pixelFormat: canvasLayer.pixelFormat,
            size: Size(canvasLayer.size),
            context: context,
            texture: texture,
            msaaTexture: msaaTexture
        )
    }

    init(activeLayer canvasLayer: CanvasLayer, context: TextureContext) {
        self.canvasLayer = canvasLayer
        isCopyOnWrite = false
        shouldClearOnNextRendering = true
        super.init(
            pixelFormat: canvasLayer.pixelFormat,
            size: Size(canvasLayer.size),
            context: context
        )
    }

    // swiftlint:disable function_body_length
    init(canvasLayer: CanvasLayer, context: TextureContext) {
        self.canvasLayer = canvasLayer
        isCopyOnWrite = false
        shouldClearOnNextRendering = false
        super.init(
            pixelFormat: canvasLayer.pixelFormat,
            size: Size(canvasLayer.size),
            context: context
        )

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

            texture = context.device.metalDevice.makeTexture(descriptor: description)!

            if let data = context.layer(id: canvasLayer.id, type: "texture") {
                BismushLogger.drawing.info("\(#function): Load texture data for \(canvasLayer.id)")
                texture.bmkData = data
                shouldClearOnNextRendering = false
            } else {
                shouldClearOnNextRendering = true
            }

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
                msaaTexture = context.device.metalDevice.makeTexture(descriptor: desc)!

                if let data = context.layer(id: canvasLayer.id, type: "msaatexture") {
                    msaaTexture?.bmkData = data
                }
            } else {
                msaaTexture = nil
            }
        case let .builtin(name: name):
            texture = context.device.resource.bultinTexture(name: name)
            shouldClearOnNextRendering = false
        }
    }

    // swiftlint:enable function_body_length

    override var renderPassDescriptor: MTLRenderPassDescriptor {
        defer {
            // TOOD: property should not clear any state.
            self.shouldClearOnNextRendering = false
        }
        let renderPassDescriptior = super.renderPassDescriptor
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

    override func makeWritable(commandBuffer: MTLCommandBuffer) {
        defer { isCopyOnWrite = false }
        guard isCopyOnWrite else {
            return
        }
        super.makeWritable(commandBuffer: commandBuffer)
    }

    // FIXME: naming?
    func copyOnWrite() -> LayerTexture {
        if canvasLayer.layerType == .empty {
            isCopyOnWrite = true

            return .init(canvasLayer: canvasLayer, context: context, texture: texture, msaaTexture: msaaTexture)
        } else {
            return self
        }
    }
}

class CanvasTexture: Texture {
    let canvas: Canvas
    var needsLayout = true

    init(canvas: Canvas, context: TextureContext) {
        self.canvas = canvas
        super.init(
            pixelFormat: canvas.pixelFormat,
            size: Size(canvas.size),
            context: context
        )
    }
}
