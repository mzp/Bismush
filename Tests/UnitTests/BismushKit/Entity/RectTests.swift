//
//  RectTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by mzp on 10/7/22.
//

import XCTest
@testable import BismushKit

final class RectTests: XCTestCase {
    func testInitPoints() throws {
        let rect = Rect<TexturePixelCoordinate>(points: [
            .init(x: 0, y: 0),
            .init(x: 0, y: 50),
            .init(x: 50, y: 50),
        ])
        XCTAssertEqual(rect, .init(x: 0, y: 0, width: 50, height: 50))
    }
}
