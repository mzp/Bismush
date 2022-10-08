//
//  TextureTileRegionTests.swift
//  Bismush
//
//  Created by mzp on 10/7/22.
//

import XCTest
@testable import BismushKit

final class TextureTileRegionTests: XCTestCase {
    private let tileSize = TextureTileSize(width: 5, height: 5)

    func testTiles() {
        let tiles = TextureTileRegion(
            x: 0,
            y: 0,
            size: TextureTileSize(width: 12, height: 12)
        ).tiles(size: tileSize)
        XCTAssertEqual(tiles, Set([
            .init(x: 0, y: 0, size: tileSize),
            .init(x: 5, y: 0, size: tileSize),
            .init(x: 10, y: 0, size: .init(width: 2, height: 5)),
            .init(x: 0, y: 5, size: tileSize),
            .init(x: 5, y: 5, size: tileSize),
            .init(x: 10, y: 5, size: .init(width: 2, height: 5)),
            .init(x: 0, y: 10, size: .init(width: 5, height: 2)),
            .init(x: 5, y: 10, size: .init(width: 5, height: 2)),
            .init(x: 10, y: 10, size: .init(width: 2, height: 2)),
        ]))
    }

    func testCover() {
        let canvas = Rect<TexturePixelCoordinate>(
            x: 0,
            y: 0,
            width: 8,
            height: 8
        )
        let singleRegion = canvas.split(
            cover: Rect(x: 1, y: 2, width: 3, height: 3),
            tileSize: tileSize
        )
        XCTAssertEqual(singleRegion, Set([
            .init(x: 0, y: 0, size: tileSize),
        ]))

        let multiRegion = canvas.split(
            cover: Rect(x: 0, y: 0, width: 6, height: 6),
            tileSize: tileSize
        )
        XCTAssertEqual(multiRegion, Set([
            .init(x: 0, y: 0, size: tileSize),
            .init(x: 5, y: 0, size: .init(width: 3, height: 5)),
            .init(x: 0, y: 5, size: .init(width: 5, height: 3)),
            .init(x: 5, y: 5, size: .init(width: 3, height: 3)),
        ]))
    }
}
