//
//  CanvasLayerTests.swift
//  Bismush
//
//  Created by mzp on 7/4/22.
//

import XCTest
@testable import BismushKit

final class CanvasLayerTests: XCTestCase {
    private var canvas: Canvas!
    private var layer: CanvasLayer!
    private var size: Size<CanvasPixelCoordinate>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        canvas = .empty
        layer = try XCTUnwrap(canvas.layers.first)
        size = layer.size
    }

    func testLayerTransform() {
        let transform = layer.transform
        XCTAssertEqual(Point(x: 0, y: 0), transform * Point(x: 0, y: 0))
        XCTAssertEqual(Point(x: 0, y: size.height), transform * Point(x: 0, y: size.height))
        XCTAssertEqual(Point(x: size.width, y: 0), transform * Point(x: size.width, y: 0))
        XCTAssertEqual(Point(x: size.width, y: size.height), transform * Point(x: size.width, y: size.height))
    }

    func testRenderTransform() {
        let transform = layer.renderTransform

        XCTAssertEqual(Point(x: -1, y: -1), transform * Point(x: 0, y: 0))
        XCTAssertEqual(Point(x: -1, y: 1), transform * Point(x: 0, y: size.height))
        XCTAssertEqual(Point(x: 1, y: -1), transform * Point(x: size.width, y: 0))
        XCTAssertEqual(Point(x: 1, y: 1), transform * Point(x: size.width, y: size.height))
    }

    func testTextureTransform() throws {
        let transform = layer.textureTransform

        XCTAssertEqual(Point(x: 0, y: 1), transform * Point(x: 0, y: 0))
        XCTAssertEqual(Point(x: 0, y: 0), transform * Point(x: 0, y: size.height))
        XCTAssertEqual(Point(x: 1, y: 1), transform * Point(x: size.width, y: 0))
        XCTAssertEqual(Point(x: 1, y: 0), transform * Point(x: size.width, y: size.height))
    }
}
