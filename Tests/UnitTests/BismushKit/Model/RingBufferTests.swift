//
//  RingBufferTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by mzp on 4/10/22.
//

import XCTest
@testable import BismushKit

class RingBufferTests: XCTestCase {
    private var ringBuffer: RingBuffer<Int>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        ringBuffer = RingBuffer(capacity: 3)
    }

    func testAppend() {
        ringBuffer.append(0)
        XCTAssertEqual([0], Array(ringBuffer))

        ringBuffer.append(1)
        XCTAssertEqual([0, 1], Array(ringBuffer))

        ringBuffer.append(2)
        XCTAssertEqual([0, 1, 2], Array(ringBuffer))

        ringBuffer.append(3)
        XCTAssertEqual([1, 2, 3], Array(ringBuffer))
    }

    func testAppendMany() {
        for element in 0 ..< 10 {
            ringBuffer.append(element)
        }
    }

    func testRemoveAll() {
        ringBuffer.append(1)
        ringBuffer.append(2)
        ringBuffer.append(3)
        ringBuffer.removeAll()
        XCTAssertEqual([], Array(ringBuffer))
    }

    func testCount() {
        ringBuffer.append(1)
        ringBuffer.append(2)
        XCTAssertEqual(2, ringBuffer.count)

        ringBuffer.append(3)
        ringBuffer.append(4)
        XCTAssertEqual(3, ringBuffer.count)
    }

    func testSubscript() {
        ringBuffer.append(0)
        ringBuffer.append(1)
        ringBuffer.append(2)
        ringBuffer.append(3)

        XCTAssertEqual(1, ringBuffer[0])
        XCTAssertEqual(2, ringBuffer[1])
        XCTAssertEqual(3, ringBuffer[2])
    }
}
