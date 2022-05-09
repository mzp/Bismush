//
//  CanvasLayerStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/31/22.
//

import Metal
import simd

protocol CanvasContext {
    var device: GPUDevice { get }
    var modelViewMatrix: Transform2D<WorldCoordinate, CanvasPixelCoordinate> { get }
}

class ArtboardLayerStore {
    let canvasLayer: CanvasLayer
    let texture: MTLTexture
    let pixelFormat: MTLPixelFormat = .rgba8Unorm

    private let context: CanvasContext
    private let msaaTexture: MTLTexture
    private var dirty = true

    init(canvasLayer: CanvasLayer, context: CanvasContext) {
        self.canvasLayer = canvasLayer
        self.context = context

        switch canvasLayer.layerType {
        case .empty:
            let description = MTLTextureDescriptor()
            description.width = Int(canvasLayer.size.width)
            description.height = Int(canvasLayer.size.height)
            description.pixelFormat = pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D

            texture = context.device.metalDevice.makeTexture(descriptor: description)!
        case let .builtin(name: name):
            texture = context.device.resource.bultinTexture(name: name)
        }

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false
        )
        desc.textureType = .type2DMultisample
        desc.sampleCount = 4
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        msaaTexture = context.device.metalDevice.makeTexture(descriptor: desc)!
    }

    var device: GPUDevice { context.device }

    func render(commandBuffer: MTLCommandBuffer, perform: (MTLRenderCommandEncoder) -> Void) {
        let renderPassDescription = MTLRenderPassDescriptor()
        renderPassDescription.colorAttachments[0].texture = msaaTexture
        renderPassDescription.colorAttachments[0].resolveTexture = texture
        renderPassDescription.colorAttachments[0].loadAction = dirty ? .clear : .load
        renderPassDescription.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        renderPassDescription.colorAttachments[0].storeAction = .storeAndMultisampleResolve
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescription)!
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(canvasLayer.size.width),
            height: Double(canvasLayer.size.height),
            znear: -1,
            zfar: 1
        )
        encoder.setViewport(viewPort)
        perform(encoder)
        encoder.endEncoding()
        dirty = false
    }

    var transform: Transform2D<LayerPixelCoordinate, CanvasPixelCoordinate> {
        .identity()
    }

    var renderTransform: Transform2D<LayerCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: -1, y: -1) *
                Transform2D.scale(x: Float(1 / canvasLayer.size.width * 2), y: Float(1 / canvasLayer.size.height * 2)))
    }

    var textureTransform: Transform2D<TextureCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: 0, y: 1) *
                Transform2D.rotate(x: .pi) *
                Transform2D.scale(x: Float(1 / canvasLayer.size.width), y: Float(1 / canvasLayer.size.height)))
    }
}
