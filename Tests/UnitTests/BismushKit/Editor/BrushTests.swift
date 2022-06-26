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
    let viewSize: Size<ViewCoordinate> = .init(width: 100, height: 100)
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
            .zero(),
            .init(x: 70, y: 20),
            .init(x: 80, y: 30),
            .init(x: 100, y: 100),
        ])
        render()
        let distance = try distance(name: "bezier", type: "png")
        XCTAssertLessThan(distance, 10)
    }

    func testMix() {
        brush.brushSize = 6
        brush.color = .red
        stroke(points: [
            .init(x: 0, y: 50),
            .init(x: 100, y: 50),
        ])
        brush.color = .blue
        // fastest
        stroke(points: [
            .init(x: 0, y: 0),
            .init(x: 0, y: 100),
        ])

        // middle
        stroke(points: [
            .init(x: 30, y: 0),
            .init(x: 30, y: 20),
            .init(x: 30, y: 40),
            .init(x: 30, y: 60),
            .init(x: 30, y: 80),
            .init(x: 30, y: 100),
        ])

        // slowest
        stroke(points: [
            .init(x: 60, y: 0),
            .init(x: 60, y: 10),
            .init(x: 60, y: 20),
            .init(x: 60, y: 30),
            .init(x: 60, y: 40),
            .init(x: 60, y: 50),
            .init(x: 60, y: 60),
            .init(x: 60, y: 70),
            .init(x: 60, y: 80),
            .init(x: 60, y: 90),
            .init(x: 60, y: 100),
        ])

        render()
    }

    func stroke(points: [Point<ViewCoordinate>]) {
        for point in points {
            brush.add(pressurePoint: .init(point: point, pressure: 1), viewSize: viewSize)
        }
        brush.commit()
    }
}
