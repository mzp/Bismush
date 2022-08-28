//
//  BismushTextureTests.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/21/22.
//

import XCTest
@testable import BismushKit

final class BismushTextureTests: XCTestCase {
    private var factory: BismushTextureFactory!
    private var commandBuffer: MTLCommandBuffer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        factory = BismushTextureFactory(device: .default)
        commandBuffer = GPUDevice.default.metalDevice.makeCommandQueue()?.makeCommandBuffer()
    }

    func testEmpty() {
        let texture = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        XCTAssertEqual(texture.loadAction, .clear)
        XCTAssertNil(texture.msaaTexture)
    }

    func testMSAATexture() {
        #if targetEnvironment(simulator)
            _ = XCTSkip("iOS Simulator(Xcode 14b5) doesn't support MSAA")
        #else
            let texture = factory.create(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 4,
                sparse: false
            )
            XCTAssertNotNil(texture.msaaTexture)
        #endif
    }

    func testTakeSnapshot_NoChange() {
        let texture = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        let snapshot1 = texture.takeSnapshot()
        let snapshot2 = texture.takeSnapshot()
        let snapshot3 = texture.takeSnapshot()
        XCTAssertIdentical(snapshot2.nsData, snapshot1.nsData)
        XCTAssertIdentical(snapshot3.nsData, snapshot1.nsData)
    }

    func testTakeSnapshot_OnChange() {
        let texture = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        let snapshot1 = texture.takeSnapshot()
        texture.withRenderPassDescriptor(commandBuffer: commandBuffer) { _ in }
        let snapshot2 = texture.takeSnapshot()
        texture.withRenderPassDescriptor(commandBuffer: commandBuffer) { _ in }
        let snapshot3 = texture.takeSnapshot()

        XCTAssertNotIdentical(snapshot2.data as NSData, snapshot1.data as NSData)
        XCTAssertNotIdentical(snapshot3.data as NSData, snapshot1.data as NSData)
    }

    func testWithRenderPassDescriptor() {
        let texture = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        let metalTexture = texture.texture
        texture.withRenderPassDescriptor(commandBuffer: commandBuffer) { description in
            XCTAssertNotNil(description.colorAttachments[0].texture)
            XCTAssertEqual(description.colorAttachments[0].storeAction, .store)
        }
        XCTAssertIdentical(texture.texture, metalTexture)
    }

    func testWithRenderPassDescriptorMSAA() {
        #if targetEnvironment(simulator)
            _ = XCTSkip("iOS Simulator(Xcode 14b5) doesn't support MSAA")
        #else
            let texture = factory.create(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 4,
                sparse: false
            )
            let metalTexture = texture.texture
            let commandBuffer = GPUDevice.default.metalDevice.makeCommandQueue()?.makeCommandBuffer()
            texture.withRenderPassDescriptor(commandBuffer: commandBuffer!) { description in
                XCTAssertNotNil(description.colorAttachments[0].texture)
                XCTAssertEqual(description.colorAttachments[0].storeAction, .storeAndMultisampleResolve)
            }
            XCTAssertIdentical(texture.texture, metalTexture)
        #endif
    }

    func testInitFromSnapshot() throws {
        let texture1 = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        texture1.withRenderPassDescriptor(commandBuffer: commandBuffer) { _ in }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(texture1.takeSnapshot())

        XCTAssertGreaterThan(data.count, 0)

        let decoder = PropertyListDecoder()
        let snapshot = try decoder.decode(BismushTexture.Snapshot.self, from: data)
        let texture2 = factory.create(
            size: .init(width: 100, height: 100),
            pixelFormat: .rgba8Unorm,
            rasterSampleCount: 1,
            sparse: false
        )
        texture2.restore(from: snapshot)

        XCTAssertEqual(texture2.texture.bmkData, texture1.texture.bmkData)
        XCTAssertEqual(texture2.size, texture1.size)
        XCTAssertEqual(texture2.loadAction, .load)
        XCTAssertEqual(texture2.pixelFormat, texture1.pixelFormat)
    }
}
