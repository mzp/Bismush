//
//  MetalMutableArrayTests.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/27/22.
//

import XCTest
@testable import BismushKit

final class MetalMutableArrayTests: XCTestCase {
    private var array: MetalMutableArray<Int>!

    override func setUp() {
        super.setUp()
        array = MetalMutableArray(device: .default, count: 10)
    }

    func testCount() {
        XCTAssertEqual(array.count, 10)
    }

    func testIsEmpty() {
        XCTAssertFalse(array.isEmpty)

        let empty = MetalMutableArray<Int>(device: .default, count: 0)
        XCTAssertTrue(empty.isEmpty)
    }

    func testRemoveAll() {
        array.removeAll(count: 20)
        XCTAssertEqual(array.count, 20)
        XCTAssertTrue(
            array.allSatisfy { $0 == 0 }
        )
    }

    func testSequence() {
        let array = Array(array)
        XCTAssertEqual(array.count, 10)
        XCTAssertTrue(
            array.allSatisfy { $0 == 0 }
        )
    }
}
