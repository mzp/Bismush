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
    let context: CanvasContext
    let canvasLayer: CanvasLayer
    let texture: MTLTexture

    init(canvasLayer: CanvasLayer, context: CanvasContext) {
        self.canvasLayer = canvasLayer
        self.context = context

        switch canvasLayer.layerType {
        case .empty:
            let description = MTLTextureDescriptor()
            description.width = Int(canvasLayer.size.width)
            description.height = Int(canvasLayer.size.height)
            description.pixelFormat = .bgra8Unorm
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D

            texture = context.device.metalDevice.makeTexture(descriptor: description)!
        case let .builtin(name: name):
            texture = context.device.resource.bultinTexture(name: name)
        }
    }

    var device: GPUDevice { context.device }

    var transform: Transform2D<LayerPixelCoordinate, CanvasPixelCoordinate> {
        .identity()
    }

    var textureTransform: Transform2D<LayerCoordinate, LayerPixelCoordinate> {
        Transform2D(matrix:
            Transform2D.translate(x: -1, y: -1) *
                Transform2D.scale(x: Float(1 / canvasLayer.size.width * 2), y: Float(1 / canvasLayer.size.height * 2)))
    }
}