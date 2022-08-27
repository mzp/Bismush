//
//  TileMapTests.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

import XCTest
@testable import BismushKit

fileprivate func point(_ x: Int, _ y: Int) -> Point<TextureCoordinate> {
    .init(x: Float(x), y: Float(y))
}

fileprivate func region(_ x: Int, _ y : Int, _ width: Int, _ height: Int) -> MTLRegion {
    .init(
        origin: .init(x: x, y: y, z: 1),
        size: .init(width: width, height: height, depth: 1)
    )
}

final class TileMapTests: XCTestCase {
    private var map: SparseTextureMap!
    
    override func setUp() {
        super.setUp()
        map = SparseTextureMap(
            size: Size(width: 200, height: 100),
            tileSize: Size(width: 10, height: 5)
        )
    }

    func testTileRegion_unmap() {
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(1, 1)]),
            [region(0, 0, 1, 1)]
        )
        
        XCTAssertEqual(
            map.tileRegion(for: [point(10, 5)]),
            [region(1, 1, 1, 1)]
        )
        
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(40, 50)]),
            [region(0, 0, 1, 1), region(4, 10, 1, 1)]
        )
    }
    
    func testTileRegion_map() {
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(40, 50)]),
            [region(0, 0, 1, 1), region(4, 10, 1, 1)]
        )
        
        map.updateMapping(in: [region(0,0,1,1)], mode: .map)
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(40, 50)]),
            [region(4, 10, 1, 1)]
        )
        
        map.updateMapping(in: [region(4,10,1,1)], mode: .map)
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(40, 50)]),
            []
        )
    }

    func testTileRegion_unify() {
        // TODO: might be diffcult
        XCTAssertEqual(
            map.tileRegion(for: [point(0, 0), point(10, 0)]),
            [region(0, 0, 1, 2)]
        )
    }
}
