//
//  CanvasTransformTests.swift
//  Bismush
//
//  Created by mzp on 7/4/22.
//

import XCTest
@testable import BismushKit

final class CanvasTransformTests: XCTestCase {
    private var canvas: Canvas!
    private var size: Size<CanvasPixelCoordinate>!

    override func setUp() {
        super.setUp()
        canvas = .empty
        size = canvas.size
    }

    func testNormalize() {
        let transform: Transform2D<ViewCoordinate, ViewPortCoordinate> = canvas.normalize(viewPortSize: Size(size))
        XCTAssertEqual(Point(x: 0, y: 0), transform * Point(x: -1, y: -1))
        XCTAssertEqual(Point(x: 0, y: size.height), transform * Point(x: -1, y: 1))
        XCTAssertEqual(Point(x: size.width, y: 0), transform * Point(x: 1, y: -1))
        XCTAssertEqual(Point(x: size.width, y: size.height), transform * Point(x: 1, y: 1))
    }

    func testProjection() {
        let transform = canvas.projection(viewPortSize: Size(size))

        XCTAssertEqual(Point(x: -1, y: -1), transform * Point(x: 0, y: 0))
        XCTAssertEqual(Point(x: -1, y: 1), transform * Point(x: 0, y: 1))
        XCTAssertEqual(Point(x: 1, y: -1), transform * Point(x: 1, y: 0))
        XCTAssertEqual(Point(x: 1, y: 1), transform * Point(x: 1, y: 1))
    }

    func testModelView() {
        let transform = canvas.modelViewMatrix

        XCTAssertEqual(Point(x: 0, y: 0), transform * Point(x: 0, y: size.height))
        XCTAssertEqual(Point(x: 0, y: 1), transform * Point(x: 0, y: 0))
        XCTAssertEqual(Point(x: 1, y: 0), transform * Point(x: size.width, y: size.height))
        XCTAssertEqual(Point(x: 1, y: 1), transform * Point(x: size.width, y: 0))
    }
}
