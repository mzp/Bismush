//
//  TileMapTests.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

import XCTest
@testable import BismushKit

private func point(_ x: Int, _ y: Int) -> Point<TextureCoordinate> {
    .init(x: Float(x), y: Float(y))
}

private func region(_ x: Int, _ y: Int, _ width: Int, _ height: Int) -> MTLRegion {
    .init(
        origin: .init(x: x, y: y, z: 0),
        size: .init(width: width, height: height, depth: 1)
    )
}

final class SparseTextureMapTests: XCTestCase {
    private var map: SparseTextureMap!

    override func setUp() {
        super.setUp()
        map = SparseTextureMap(
            device: .default,
            size: Size(width: 200, height: 100),
            tileSize: MTLSize(width: 10, height: 5, depth: 1)
        )
    }

    func testTileRegion() {
        XCTAssertNil(
            map.unmappingRegion(for: [])
        )
        XCTAssertEqual(
            map.unmappingRegion(for: [point(0, 0), point(1, 1)]),
            region(0, 0, 1, 1)
        )

        XCTAssertEqual(
            map.unmappingRegion(for: [point(10, 5)]),
            region(1, 1, 1, 1)
        )

        XCTAssertEqual(
            map.unmappingRegion(for: [point(10, 5), point(40, 50)]),
            region(1, 1, 4, 10)
        )
    }

    func testUpdateMapping() {
        XCTAssertEqual(
            map.unmappingRegion(for: [point(0, 0), point(39, 49)]),
            region(0, 0, 4, 10)
        )

        map.updateMapping(region: region(0, 0, 1, 1))

        XCTAssertEqual(
            map.unmappingRegion(for: [point(0, 0), point(39, 49)]),
            region(3, 9, 1, 1)
        )

        map.updateMapping(region: region(4, 10, 1, 1))
        XCTAssertNil(
            map.unmappingRegion(for: [point(0, 0), point(39, 49)])
        )
    }

    func testUpdateMapping_max() {
        map.updateMapping(region: region(0, 0, 20, 20))
    }
}
