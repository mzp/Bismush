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
    private var commandBuffer: SequencialCommandBuffer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        factory = BismushTextureFactory(device: .default)
        commandBuffer = GPUDevice.default.makeCommandQueue(label: #fileID).makeSequencialCommandBuffer(label: #fileID)
    }

    func testEmpty() {
        let texture = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1
            )
        )
        XCTAssertEqual(texture.loadAction, .clear)
        XCTAssertNil(texture.msaaTexture)
    }

    func testMSAATexture() {
        #if targetEnvironment(simulator)
            _ = XCTSkip("iOS Simulator(Xcode 14b5) doesn't support MSAA")
        #else
            let texture = factory.create(
                .init(
                    size: .init(width: 100, height: 100),
                    pixelFormat: .rgba8Unorm,
                    rasterSampleCount: 4
                )
            )
            XCTAssertNotNil(texture.msaaTexture)
        #endif
    }

    func testTakeSnapshot_NoChange() {
        let texture = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1,
                tileSize: nil
            )
        )
        let snapshot1 = texture.takeSnapshot()
        let snapshot2 = texture.takeSnapshot()
        let snapshot3 = texture.takeSnapshot()
        XCTAssertEqual(snapshot1, snapshot2)
        XCTAssertEqual(snapshot2, snapshot3)
    }

    func testTakeSnapshot_OnChange() {
        let texture = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1,
                tileSize: nil
            )
        )
        let snapshot1 = texture.takeSnapshot()
        texture.asRenderTarget(commandBuffer: commandBuffer) { _ in }
        let snapshot2 = texture.takeSnapshot()
        texture.asRenderTarget(commandBuffer: commandBuffer) { _ in }
        let snapshot3 = texture.takeSnapshot()

        XCTAssertNotEqual(snapshot2, snapshot1)
        XCTAssertNotEqual(snapshot3, snapshot1)
    }

    func testWithRenderPassDescriptor() {
        let texture = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1
            )
        )
        let metalTexture = texture.texture
        texture.asRenderTarget(commandBuffer: commandBuffer) { description in
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
                .init(
                    size: .init(width: 100, height: 100),
                    pixelFormat: .rgba8Unorm,
                    rasterSampleCount: 4
                )
            )
            let metalTexture = texture.texture
            var commandBuffer = GPUDevice.default
                .makeCommandQueue(label: #fileID)
                .makeSequencialCommandBuffer(label: #fileID)
            texture.asRenderTarget(commandBuffer: commandBuffer) { description in
                XCTAssertNotNil(description.colorAttachments[0].texture)
                XCTAssertEqual(description.colorAttachments[0].storeAction, .storeAndMultisampleResolve)
            }
            commandBuffer.commit()
            XCTAssertIdentical(texture.texture, metalTexture)
        #endif
    }

    func testInitFromSnapshot() throws {
        let texture1 = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1
            )
        )
        texture1.asRenderTarget(commandBuffer: commandBuffer) { _ in }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(texture1.takeSnapshot())

        XCTAssertGreaterThan(data.count, 0)

        let decoder = PropertyListDecoder()
        let snapshot = try decoder.decode(BismushTexture.Snapshot.self, from: data)
        let texture2 = factory.create(
            .init(
                size: .init(width: 100, height: 100),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1
            )
        )
        texture2.restore(from: snapshot)

        XCTAssertEqual(texture2.texture.bmkData, texture1.texture.bmkData)
        XCTAssertEqual(texture2.loadAction, .load)
        XCTAssertEqual(texture2.descriptor, texture1.descriptor)
    }
}
