//
//  WaterColor.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation

class WaterColorMix {
    private let document: CanvasDocument
    private var context: BMKLayerContext
    private var currentColor: MTLBuffer
    private let shader: ShaderStore
    private var initialized = false

    init(document: CanvasDocument, context: BMKLayerContext) {
        self.document = document
        self.context = context
        var color = context.brushColor
        currentColor = document.device.metalDevice.makeBuffer(
            bytes: &color,
            length: MemorySize.float4,
            options: .storageModeShared
        )!
        shader = document.device.shader()
    }

    private func updateCurrentColor(strokes: MetalMutableArray<BMKStroke> /* only use first element */ ) {
        assert(!strokes.isEmpty)
        try! shader.compute(.waterColorInit) { encoder in
            encoder.setBuffer(currentColor, offset: 0, index: 0)
            encoder.setTexture(document.texture(canvasLayer: document.activeLayer).texture, index: 1)
            encoder.setBytes(&context, length: MemoryLayout<BMKLayerContext>.size, index: 2)
            encoder.setBuffer(strokes.content, offset: 0, index: 3)

            encoder.dispatchThreadgroups(
                MTLSize(width: 1, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
        }
        let color = currentColor.contents().load(as: SIMD4<Float>.self)
        BismushLogger.drawing.trace("""
        \(#function) Color: (\
        \(color.x, format: .fixed(precision: 2)), \
        \(color.y, format: .fixed(precision: 2)), \
        \(color.z, format: .fixed(precision: 2)), \
        \(color.w, format: .fixed(precision: 2)))
        """)
    }

    func mix(strokes: MetalMutableArray<BMKStroke>) {
        if !initialized {
            updateCurrentColor(strokes: strokes)
            initialized = true
        }

        let color = currentColor.contents().load(as: SIMD4<Float>.self)
        BismushLogger.drawing.trace("""
        \(#function) Color: (\
        \(color.x, format: .fixed(precision: 2)), \
        \(color.y, format: .fixed(precision: 2)), \
        \(color.z, format: .fixed(precision: 2)), \
        \(color.w, format: .fixed(precision: 2)))
        """)
        try! shader.compute(.waterColorMix) { encoder in
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
