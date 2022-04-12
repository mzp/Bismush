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
    private var points = RingBuffer<Point<ViewCoordinate>>(capacity: 4)

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
        renderer = nil
        points.removeAll()
    }

    public func add(point: Point<ViewCoordinate>, viewSize: Size<ViewCoordinate>) {
        BismushLogger.metal.debug("Add stroke <point: \(point), size: \(viewSize)>")
        points.append(point)

        if points.count == 4 {
            if renderer == nil {
                renderer = StrokeRenderer(store: store, size: viewSize)
            }
            renderer?.render(
                point0: points[0],
                point1: points[1],
                point2: points[2],
                point3: points[3]
            )
        }
    }
}
