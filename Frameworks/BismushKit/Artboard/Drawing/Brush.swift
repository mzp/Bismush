//
//  BrushRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//

import CoreGraphics
import Metal
import simd

public class Brush {
    private let store: ArtboardStore
    private var renderer: StrokeRenderer?
    private var inputEvents = RingBuffer<PenInputEvent>(capacity: 4)

    public init(store: ArtboardStore) {
        self.store = store
    }

    static let renderPipelineDescriptor: MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].isBlendingEnabled = true

        // alpha blending
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
        return descriptor
    }()

    public func clear() {
        BismushLogger.metal.debug("Clear strokes")
        renderer = nil
        inputEvents.removeAll()
    }

    public func add(inputEvent: PenInputEvent, viewSize: Size<ViewCoordinate>) {
        BismushLogger.metal.debug("Add stroke \(inputEvent.debugDescription)")
        inputEvents.append(inputEvent)

        if inputEvents.count == 4 {
            if renderer == nil {
                renderer = StrokeRenderer(store: store, size: viewSize)
            }
            renderer?.render(
                input0: inputEvents[0],
                input1: inputEvents[1],
                input2: inputEvents[2],
                input3: inputEvents[3]
            )
        }
    }
}
