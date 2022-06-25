//
//  BezierInterpolate.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation

class BezierInterpolate {
    private let shader: ShaderStore
    private let transform: Transform2D<LayerPixelCoordinate, ViewCoordinate>
    private var strokes: MetalMutableArray<BMKStroke>

    init(document: CanvasDocument, size: Size<ViewCoordinate>) {
        shader = document.device.shader()
        transform =
            document.activeLayer.transform *
            (document.canvas.normalize(viewPortSize: size) *
                document.canvas.projection(viewPortSize: size) *
                document.canvas.modelViewMatrix).inverse

        strokes = document.device.makeArray(options: .storageModeShared)
    }

    func interpolate(
        input0: PressurePoint,
        input1: PressurePoint,
        input2: PressurePoint,
        input3: PressurePoint
    ) -> MetalMutableArray<BMKStroke> {
        try! shader.compute(.bezierInterpolation) { encoder in
            var point0 = transform * input0
            var point1 = transform * input1
            var point2 = transform * input2
            var point3 = transform * input3
            let length = simd_distance(point0.xy, point1.xy) +
                simd_distance(point1.xy, point2.xy) +
                simd_distance(point2.xy, point3.xy)
            let count = Int(max(ceil(length / 2), 4))
            BismushLogger.drawing.trace("Bezier interpolate: count=\(count)")
            strokes.use(count: count)
            encoder.setBuffer(strokes.content, offset: 0, index: 0)

            encoder.setBytes(&point0, length: MemorySize.float3, index: 1)
            encoder.setBytes(&point1, length: MemorySize.float3, index: 2)
            encoder.setBytes(&point2, length: MemorySize.float3, index: 3)
            encoder.setBytes(&point3, length: MemorySize.float3, index: 4)

            var delta = 1 / Float(count)
            encoder.setBytes(&delta, length: MemoryLayout<Float>.size, index: 5)

            encoder.dispatchThreadgroups(
                MTLSize(width: count, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
        }
        return strokes
    }
}
