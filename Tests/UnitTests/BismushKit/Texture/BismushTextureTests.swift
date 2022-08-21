//
//  BismushTextureTests.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import XCTest
@testable import BismushKit

final class BismushTextureTests: XCTestCase {
    var factory: BismushTextureFactory!

    override func setUpWithError() throws {
        factory = BismushTextureFactory(device: .default)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEmptyTexture() {
       let texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        XCTAssertNotNil(texture.msaaTexture)
        XCTAssertEqual(texture.loadAction, .clear)

    }

    func testCopyTexture() {
        let texture1 = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let texture2 = texture1.copy()
        let texture3 = texture2.copy()

        XCTAssertEqual(texture2.loadAction, .load)
        XCTAssertIdentical(texture2.texture, texture1.texture)

        XCTAssertEqual(texture3.loadAction, .load)
        XCTAssertIdentical(texture3.texture, texture2.texture)
    }

    func testWriteOnEmpty() {
        var texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let metalTexture = texture.texture
        texture.withRenderPassDescriptor { description in
            XCTAssertNotNil(description.colorAttachments[0].texture)
            XCTAssertIdentical(description.colorAttachments[0].resolveTexture, metalTexture)
            XCTAssertEqual(description.colorAttachments[0].storeAction, .storeAndMultisampleResolve)
        }
    }

    func testWriteOnCopyEmpty() {
        let texture1 = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let metalTexture1 = texture1.texture

        var texture2 = texture1.copy().mutable()
        texture2.withRenderPassDescriptor { description in
            XCTAssertNotNil(description.colorAttachments[0].texture)
            XCTAssertNotIdentical(description.colorAttachments[0].resolveTexture, metalTexture1)
            XCTAssertEqual(description.colorAttachments[0].storeAction, .storeAndMultisampleResolve)
        }
    }

    func testRestore() {
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
