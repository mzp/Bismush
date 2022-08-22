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

    func testEmptyTexture() {
       let texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        XCTAssertNotNil(texture.msaaTexture)
        XCTAssertEqual(texture.loadAction, .clear)
    }

    func testTakeSnapshot_NoChange() {
       let texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let snapshot1 = texture.takeSnapshot()
        let snapshot2 = texture.takeSnapshot()
        let snapshot3 = texture.takeSnapshot()
        XCTAssertIdentical(snapshot2.data as NSData, snapshot1.data as NSData)
        XCTAssertIdentical(snapshot3.data as NSData, snapshot1.data as NSData)
    }

    func testTakeSnapshot_OnChange() {
        let texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let snapshot1 = texture.takeSnapshot()
        texture.withRenderPassDescriptor { _ in }
        let snapshot2 = texture.takeSnapshot()
        texture.withRenderPassDescriptor { _ in }
        let snapshot3 = texture.takeSnapshot()

        XCTAssertNotIdentical(snapshot2.data as NSData, snapshot1.data as NSData)
        XCTAssertNotIdentical(snapshot3.data as NSData, snapshot1.data as NSData)
    }

    func testWithRenderPassDescriptor() {
        let texture = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        let metalTexture = texture.texture
        texture.withRenderPassDescriptor { description in
            XCTAssertNotNil(description.colorAttachments[0].texture)
            XCTAssertIdentical(description.colorAttachments[0].resolveTexture, metalTexture)
            XCTAssertEqual(description.colorAttachments[0].storeAction, .storeAndMultisampleResolve)
        }
        XCTAssertIdentical(texture.texture, metalTexture)
    }

    func testInitFromSnapshot() throws {
        let texture1 = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        texture1.withRenderPassDescriptor { _ in }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(texture1.takeSnapshot())

        XCTAssertGreaterThan(data.count, 0)

        let decoder = PropertyListDecoder()
        let snapshot = try decoder.decode(BismushTexture.Snapshot.self, from: data)
        let texture2 = factory.create(size: .init(width: 100, height: 100), pixelFormat: .rgba8Unorm)
        texture2.restore(from: snapshot)

        XCTAssertEqual(texture2.texture.bmkData, texture1.texture.bmkData)
        XCTAssertEqual(texture2.size, texture1.size)
        XCTAssertEqual(texture2.loadAction, .load)
        XCTAssertEqual(texture2.pixelFormat, texture1.pixelFormat)
    }
}
