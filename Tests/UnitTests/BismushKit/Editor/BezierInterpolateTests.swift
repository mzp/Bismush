//
//  BezierInterpolateTests.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import simd
import XCTest
@testable import BismushKit

final class BezierInterpolateTests: XCTestCase {
    private let document: CanvasDocument = .empty
    private var interpolate: BezierInterpolate!
    private var commandBuffer: SequencialCommandBuffer!
    override func setUp() {
        super.setUp()
        interpolate = BezierInterpolate(
            document: document
        )
        interpolate.viewSize = Size(document.canvas.size)
        commandBuffer = GPUDevice.default.makeCommandQueue(label: #fileID).makeSequencialCommandBuffer(label: #fileID)
    }

    func testInterpolateDense() {
        let points = interpolate.interpolate(
            input0: .init(x: 0, y: 0),
            input1: .init(x: 1, y: 1),
            input2: .init(x: 2, y: 2),
            input3: .init(x: 3, y: 3),
            commandBuffer: commandBuffer
        )
        commandBuffer.commit()
        XCTAssertGreaterThanOrEqual(points.count, 4)
    }

    func testInterpolateSparse() {
        let points = interpolate.interpolate(
            input0: .init(x: 0, y: 0),
            input1: .init(x: 0, y: 0),
            input2: .init(x: 0, y: 0),
            input3: .init(x: 800, y: 800),
            commandBuffer: commandBuffer
        )
        commandBuffer.commit()
        XCTAssertGreaterThanOrEqual(points.count, 800)
    }

    func testInterpolateInvariant() {
        let points =
            interpolate.interpolate(
                input0: .init(x: 0, y: 0),
                input1: .init(x: 200, y: 300),
                input2: .init(x: 400, y: 500),
                input3: .init(x: 800, y: 800),
                commandBuffer: commandBuffer
            )
        commandBuffer.commit()
        var max: Float = 1.0
        var count = 0
        for (previous, current) in zip(points, points.dropFirst()) {
            let distance = simd_distance(previous.point.xy, current.point.xy)
            if distance > 1 {
                BismushLogger.testing.warning("distance(\(current.point.xy), \(previous.point.xy)) = \(distance)")
                if distance > max {
                    max = distance
                }
                count += 1
            }
        }

        XCTAssertLessThanOrEqual(max, 1.0)
        XCTAssertEqual(count, 0)
    }

    // FIXME: Add Test: no oversampling
}
