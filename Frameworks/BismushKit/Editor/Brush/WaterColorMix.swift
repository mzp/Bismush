//
//  WaterColor.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation

class WaterColorMix {
    private let document: CanvasDocument
    private var currentColor: MTLBuffer
    private let shader: ShaderStore
    private var initialized = false

    init(document: CanvasDocument) {
        self.document = document
        currentColor = document.device.makeBuffer(
            length: MemorySize.float4
        )
        shader = document.device.shader()
    }

    func reset() {
        initialized = false
    }

    private func updateCurrentColor(
        strokes: MetalMutableArray<BMKStroke> /* only use first element */,
        context: inout BMKLayerContext,
        commandBuffer: SequencialCommandBuffer
    ) {
        assert(!strokes.isEmpty)
        try! shader.compute(.waterColorInit, commandBuffer: commandBuffer) { encoder in
            encoder.setBuffer(currentColor, offset: 0, index: 0)
            encoder.setTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 1)
            encoder.setBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 2)
            encoder.setBuffer(strokes.content, offset: 0, index: 3)

            encoder.dispatchThreadgroups(
                MTLSize(width: 1, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
        }
    }

    func mix(
        strokes: MetalMutableArray<BMKStroke>,
        context: inout BMKLayerContext,
        commandBuffer: SequencialCommandBuffer
    ) {
        if !initialized {
            updateCurrentColor(strokes: strokes, context: &context, commandBuffer: commandBuffer)
            initialized = true
        }
        try! shader.compute(.waterColorMix, commandBuffer: commandBuffer) { encoder in
            var count = strokes.count
            encoder.setBuffer(strokes.content, offset: 0, index: 0)
            encoder.setBytes(&count, length: MemorySize.uint32, index: 1)
            encoder.setBuffer(currentColor, offset: 0, index: 2)
            encoder.setTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 3)
            encoder.setBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 4)

            encoder.dispatchThreadgroups(
                MTLSize(width: 1, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
        }
    }
}
