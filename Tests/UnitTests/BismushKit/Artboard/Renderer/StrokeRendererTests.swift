//
//  StrokeRendererTests.swift
//  Bismush
//
//  Created by mzp on 4/3/22.
//

import XCTest
@testable import BismushKit

class StrokeRendererTests: RendererTestCase {
    private var renderer: StrokeRenderer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        renderer = StrokeRenderer(store: store, size: .init(width: 100, height: 100))
    }

    func testRender() throws {
        renderer.render(
            input0: .init(point: .zero(), pressure: 1),
            input1: .init(point: .init(x: 70, y: 20), pressure: 1),
            input2: .init(point: .init(x: 80, y: 30), pressure: 1),
            input3: .init(point: .init(x: 100, y: 100), pressure: 1)
        )
        let distance = distance(name: "bezier", type: "png")
        XCTAssertLessThan(distance, 5)
    }
}
