//
//  MetalObjectTests.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import XCTest
@testable import BismushKit

final class MetalObjectTests: XCTestCase {
    private struct TestObject {
        var foo: Int
        var bar: Float
    }

    private var object: MetalObject<TestObject>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        object = try MetalObject(TestObject(foo: 1, bar: 2), device: .default)
    }

    func testValue() {
        XCTAssertEqual(object.value.foo, 1)
        object.value.foo = 0
        XCTAssertEqual(object.value.foo, 0)
    }
}
