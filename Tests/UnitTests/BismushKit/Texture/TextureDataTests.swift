//
//  TileMapTests.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

import XCTest
@testable import BismushKit

final class TileRegionTests: XCTestCase {
    func testTiles() {
        let tileSize = TextureTileSize(width: 5, height: 5)
        let tiles = TextureTileRegion(x: 0, y: 0, size: TextureTileSize(width: 10, height: 10)).tiles(size: tileSize)
        XCTAssertEqual(tiles, Set([
            .init(x: 0, y: 0, size: tileSize),
            .init(x: 5, y: 0, size: tileSize),
            .init(x: 0, y: 5, size: tileSize),
            .init(x: 5, y: 5, size: tileSize),
        ]))
    }
}
