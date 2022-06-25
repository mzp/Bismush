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

    func testRender() throws {
        #if targetEnvironment(simulator)
            _ = XCTSkip("iOS Simulator(Xcode 14b2) doesn't support vision VNFeaturePrintObservation")
        #endif
        brush.color = BismushColor(red: 1, green: 1, blue: 1, alpha: 1)
        brush.add(pressurePoint: .init(point: .zero(), pressure: 1), viewSize: viewSize)
        brush.add(pressurePoint: .init(point: .init(x: 70, y: 20), pressure: 1), viewSize: viewSize)
        brush.add(pressurePoint: .init(point: .init(x: 80, y: 30), pressure: 1), viewSize: viewSize)
        brush.add(pressurePoint: .init(point: .init(x: 100, y: 100), pressure: 1), viewSize: viewSize)
        render()
        let distance = try distance(name: "bezier", type: "png")
        XCTAssertLessThan(distance, 10)
    }
}
