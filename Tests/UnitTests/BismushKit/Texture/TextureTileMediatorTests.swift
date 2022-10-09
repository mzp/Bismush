//
//  TileMapTests.swift
//  Bismush
//
//  Created by mzp on 8/27/22.
//

import XCTest
@testable import BismushKit

class TextureTileDelegateMock: TextureTileDelegate {
    enum Action: Equatable {
        case allocate(regions: Set<TextureTileRegion>)
        case free(regions: Set<TextureTileRegion>)
        case load(region: TextureTileRegion)
        case store(region: TextureTileRegion, blob: Blob)
        case snapshot(tiles: [TextureTileRegion: Blob])
    }

    let blob: Blob
    init(blob: Blob) {
        self.blob = blob
    }

    var actions = [Action]()

    func clear() {
        actions.removeAll()
    }

    func textureTileAllocate(regions: Set<TextureTileRegion>, commandBuffer _: MTLCommandBuffer) {
        actions.append(.allocate(regions: regions))
    }

    func textureTileFree(regions: Set<TextureTileRegion>, commandBuffer _: MTLCommandBuffer) {
        actions.append(.free(regions: regions))
    }

    func textureTileLoad(region: TextureTileRegion) -> Blob? {
        actions.append(.load(region: region))
        return blob
    }

    func textureTileStore(region: TextureTileRegion, blob: Blob) {
        actions.append(.store(region: region, blob: blob))
    }

    func textureTileSnapshot(tiles: [TextureTileRegion: Blob]) {
        actions.append(.snapshot(tiles: tiles))
    }
}

// swiftlint:disable single_test_class

final class TextureTileMediatorSparseTests: XCTestCase {
    private var delegateMock: TextureTileDelegateMock!
    private var mediator: TextureTileMediator!
    private var commandBuffer: MTLCommandBuffer!
    private let blob = Blob(data: "test".data(using: .utf8)! as NSData)

    override func setUp() {
        super.setUp()
        mediator = TextureTileMediator(
            descriptor: .init(
                size: .init(width: 800, height: 800),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1,
                tileSize: .init(width: 400, height: 400)
            )
        )
        delegateMock = TextureTileDelegateMock(blob: blob)
        mediator.delegate = delegateMock
        commandBuffer = GPUDevice.default.metalDevice.makeCommandQueue()?.makeCommandBuffer()
    }

    func testInitialize() {
        mediator.initialize(loadAction: .clear)
        XCTAssertNil(delegateMock.actions.last)
    }

    func testAsRenderTarget() {
        let rect = Rect<TexturePixelCoordinate>(
            x: 3,
            y: 4,
            width: 200,
            height: 200
        )
        let region = TextureTileRegion(
            x: 0,
            y: 0,
            width: 400,
            height: 400
        )
        mediator.asRenderTarget(rect: rect, commandBuffer: commandBuffer)
        XCTAssertEqual(delegateMock.actions.count, 2)
        XCTAssertEqual(delegateMock.actions[0], .snapshot(tiles: [:]))
        XCTAssertEqual(delegateMock.actions[1], .allocate(regions: Set([region])))

        delegateMock.clear()
        mediator.asRenderTarget(rect: rect, commandBuffer: commandBuffer)

        XCTAssertEqual(delegateMock.actions[0], .load(region: region))
        XCTAssertEqual(delegateMock.actions[1], .snapshot(tiles: [region: delegateMock.blob]))
    }

    func testRestore() {
        let region1 = TextureTileRegion(
            x: 0,
            y: 0,
            width: 400,
            height: 400
        )
        mediator.restore(tiles: [region1: blob], commandBuffer: commandBuffer)
        XCTAssertEqual(delegateMock.actions[0], .allocate(regions: Set([region1])))
        XCTAssertEqual(delegateMock.actions[1], .store(region: region1, blob: blob))

        delegateMock.clear()
        let region2 = TextureTileRegion(
            x: 400,
            y: 0,
            width: 400,
            height: 400
        )
        mediator.restore(tiles: [region2: blob], commandBuffer: commandBuffer)
        XCTAssertEqual(delegateMock.actions[0], .free(regions: Set([region1])))
        XCTAssertEqual(delegateMock.actions[1], .allocate(regions: Set([region2])))
        XCTAssertEqual(delegateMock.actions[2], .store(region: region2, blob: blob))
    }
}

final class TextureTileMediatorDenseTests: XCTestCase {
    private var delegateMock: TextureTileDelegateMock!
    private var mediator: TextureTileMediator!
    private var commandBuffer: MTLCommandBuffer!
    private let region = TextureTileRegion(x: 0, y: 0, width: 800, height: 800)
    private let blob = Blob(data: "hello".data(using: .utf8)! as NSData)
    override func setUp() {
        super.setUp()
        mediator = TextureTileMediator(
            descriptor: .init(
                size: .init(width: 800, height: 800),
                pixelFormat: .rgba8Unorm,
                rasterSampleCount: 1
            )
        )
        delegateMock = TextureTileDelegateMock(blob: blob)
        mediator.delegate = delegateMock
        commandBuffer = GPUDevice.default.metalDevice.makeCommandQueue()?.makeCommandBuffer()
    }

    func testInitialize() {
        mediator.initialize(loadAction: .load)
        XCTAssertEqual(delegateMock.actions[0], .load(region: region))
        XCTAssertEqual(delegateMock.actions[1], .snapshot(tiles: [region: blob]))
    }

    func testAsRenderTarget() {
        let rect = Rect<TexturePixelCoordinate>(
            x: 3,
            y: 4,
            width: 200,
            height: 200
        )
        mediator.asRenderTarget(rect: rect, commandBuffer: commandBuffer)
        XCTAssertEqual(delegateMock.actions[0], .load(region: region))
        XCTAssertEqual(delegateMock.actions[1], .snapshot(tiles: [region: blob]))
    }

    func testRestore() {
        mediator.restore(tiles: [region: delegateMock.blob], commandBuffer: commandBuffer)
        XCTAssertEqual(delegateMock.actions[0], .store(region: region, blob: blob))
    }
}
