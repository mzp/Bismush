//
//  RectTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by mzp on 10/7/22.
//

import XCTest
@testable import BismushKit

final class RectTests: XCTestCase {
    func testInitPoints() {
        let rect = Rect<TexturePixelCoordinate>(points: [
            .init(x: 0, y: 0),
            .init(x: 0, y: 50),
            .init(x: 50, y: 50),
        ])
        XCTAssertEqual(rect, .init(x: 0, y: 0, width: 50, height: 50))
    }

    func testAddInsets() {
        var rect = Rect<TexturePixelCoordinate>(
            origin: .init(x: 10, y: 10),
            size: .init(width: 30, height: 30)
        )
        rect.add(insets: .init(
            top: 3,
            left: 4,
            bottom: 5,
            right: 6
        ))
        XCTAssertEqual(rect.origin.x, 14)
        XCTAssertEqual(rect.origin.y, 13)
        XCTAssertEqual(rect.size.width, 20)
        XCTAssertEqual(rect.size.height, 22)
    }
}
