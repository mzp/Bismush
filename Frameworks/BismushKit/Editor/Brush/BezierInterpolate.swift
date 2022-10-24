//
//  BezierInterpolate.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation

class BezierInterpolate {
    private let document: CanvasDocument
    private let shader: ShaderStore
    private var strokes: MetalMutableArray<BMKStroke>

    init(document: CanvasDocument) {
        self.document = document
        shader = document.device.shader()
        strokes = document.device.makeArray(count: 0)
    }

    var viewSize: Size<ViewCoordinate> = .zero() {
        didSet {
            transform =
                document.activeLayer.transform *
                (document.canvas.normalize(viewPortSize: viewSize) *
                    document.canvas.projection(viewPortSize: viewSize) *
                    document.canvas.modelViewMatrix).inverse
        }
    }

    var transform: Transform2D<LayerPixelCoordinate, ViewCoordinate> = .identity()

    func interpolate(
        input0: PressurePoint,
        input1: PressurePoint,
        input2: PressurePoint,
        input3: PressurePoint,
        commandBuffer: SequencialCommandBuffer
    ) -> MetalMutableArray<BMKStroke> {
        BismushLogger.drawing.trace("\(#function): \(input0) \(input1) \(input2) \(input3)")

        try! shader.compute(.bezierInterpolation, commandBuffer: commandBuffer) { encoder in
            var point0 = transform * input0
            var point1 = transform * input1
            var point2 = transform * input2
            var point3 = transform * input3
            let length = simd_distance(point0.xy, point1.xy) +
                simd_distance(point1.xy, point2.xy) +
                simd_distance(point2.xy, point3.xy)
            let count = Int(max(length * 1.5, 4))
            BismushLogger.drawing.trace("\(#function): count=\(count)")
            strokes.removeAll(count: count)
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
