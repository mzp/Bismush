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
            point0: .zero(),
            point1: .init(x: 70, y: 20),
            point2: .init(x: 80, y: 30),
            point3: .init(x: 100, y: 100)
        )
        let distance = distance(name: "bezier", type: "png")
        XCTAssertLessThan(distance, 5)
    }
}
