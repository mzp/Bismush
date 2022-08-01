//
//  CanvasTexture.swift
//  Bismush
//
//  Created by mzp on 7/31/22.
//

import Foundation
protocol CanvasTextureContext {
    var device: GPUDevice { get }
}

class CanvasTexture: Equatable, TextureType {
    let canvas: Canvas
    var needsLayout: Bool = true
    private let context: LayerTextureContext
    private(set) var texture: MTLTexture
    private(set) var msaaTexture: MTLTexture?

    var size: Size<TextureCoordinate> {
        Size(canvas.size)
    }

    init(canvas: Canvas, context: LayerTextureContext) {
        self.canvas = canvas
        self.context = context

        let size = canvas.size
        let width = Int(size.width)
        let height = Int(size.height)

        let description = MTLTextureDescriptor()
        description.width = width
        description.height = height
        description.pixelFormat = canvas.pixelFormat
        description.usage = [.shaderRead, .renderTarget, .shaderWrite]
        description.textureType = .type2D

        let texture = context.device.metalDevice.makeTexture(descriptor: description)!
        self.texture = texture

        if context.device.capability.msaa {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: canvas.pixelFormat,
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

        renderPassDescriptior.colorAttachments[0].loadAction = .clear
        renderPassDescriptior.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        return renderPassDescriptior
    }

    func makeWritable(commandBuffer: MTLCommandBuffer) {
        if let encoder = commandBuffer.makeBlitCommandEncoder() {
            let description = MTLTextureDescriptor()
            description.width = Int(canvas.size.width)
            description.height = Int(canvas.size.height)
            description.pixelFormat = canvas.pixelFormat
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

    static func == (lhs: CanvasTexture, rhs: CanvasTexture) -> Bool {
        lhs.texture.bmkData == rhs.texture.bmkData &&
            lhs.msaaTexture?.bmkData == rhs.msaaTexture?.bmkData
    }
}
