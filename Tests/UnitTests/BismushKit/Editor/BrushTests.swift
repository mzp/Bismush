//
//  BrushTest.swift
//  Bismush
//
//  Created by mzp on 4/3/22.
//

import XCTest
@testable import BismushKit

class BrushTests: RenderingTestCase {
    private var brush: Brush!
    override func setUpWithError() throws {
        try super.setUpWithError()
        brush = Brush(document: document, brushSize: 10)
    }

    func testBezierInterpolate() throws {
        #if targetEnvironment(simulator)
            _ = XCTSkip("iOS Simulator(Xcode 14b2) doesn't support vision VNFeaturePrintObservation")
        #endif

        brush.color = .white
        stroke(points: [
            .init(x: 0, y: 800),
            .init(x: 420, y: 640),
            .init(x: 640, y: 560),
            .init(x: 800, y: 0),
        ])
        render()
        let distance = try distance(name: "bezier", type: "png")
        XCTAssertLessThan(distance, 10)
    }

    func testMix() throws {
        brush.color = .red
        stroke(points: [
            .init(x: 0, y: 200),
            .init(x: 800, y: 200),
        ])

        stroke(points: [
            .init(x: 0, y: 400),
            .init(x: 800, y: 400),
        ])

        stroke(points: [
            .init(x: 0, y: 600),
            .init(x: 800, y: 600),
        ])
        brush.color = .blue
        brush.brushSize = 30
        // fastest
        stroke(points: [
            .init(x: 80, y: 0),
            .init(x: 80, y: 800),
        ])

        // middle
        stroke(points: [
            .init(x: 400, y: 0),
            .init(x: 400, y: 160),
            .init(x: 400, y: 320),
            .init(x: 400, y: 480),
            .init(x: 400, y: 650),
            .init(x: 400, y: 800),
        ])

        // slowest
        stroke(points: [
            .init(x: 720, y: 0),
            .init(x: 720, y: 60),
            .init(x: 720, y: 120),
            .init(x: 720, y: 180),
            .init(x: 720, y: 240),
            .init(x: 720, y: 300),
            .init(x: 720, y: 480),
            .init(x: 720, y: 560),
            .init(x: 720, y: 640),
            .init(x: 720, y: 720),
            .init(x: 720, y: 800),
        ])

        render()

        try openWithPreview()
    }

    func stroke(points: [Point<ViewCoordinate>]) {
        for point in points {
            brush.add(pressurePoint: .init(point: point, pressure: 1), viewSize: viewSize)
        }
        brush.commit()
    }
}
