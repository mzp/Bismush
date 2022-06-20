//
//  ArtboardLayerStoreTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by Hiro Mizuno on 6/11/22.
//

import CoreGraphics
import XCTest
@testable import BismushKit

class DummyContext: RenderContext, DocumentContext {
    var data: Data?
    var device: GPUDevice { .default }

    var modelViewMatrix: Transform2D<WorldCoordinate, CanvasPixelCoordinate> {
        .identity()
    }

    func layer(id _: String) -> Data? {
        data
    }
}

class ArtboardLayerStoreTests: XCTestCase {
    private var context: DummyContext!
    override func setUp() {
        super.setUp()
        context = DummyContext()
    }

    func testData() throws {
        let layer = CanvasLayer(
            name: "#yosemite",
            layerType: .builtin(name: "yosemite"),
            size: .init(width: 800, height: 800)
        )
        let context = DummyContext()
        let store = CanvasLayerRenderer(canvasLayer: layer, documentContext: context, renderContext: context)
        let data = store.data

        let dataLayer = CanvasLayer(
            name: "#yosemite",
            layerType: .empty,
            size: .init(width: 800, height: 800)
        )
        context.data = data
        let restoredStore = CanvasLayerRenderer(canvasLayer: dataLayer, documentContext: context, renderContext: context)
        let restoredData = restoredStore.data

        let attachment = XCTAttachment(image: try XCTUnwrap(image(data, width: 800, height: 800)))
        attachment.name = "data"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(data, restoredData)
    }

    private func image(_ data: Data, width: Int, height: Int) -> NSImage? {
        if let cgImage = BismushInspector.image(data, width: width, height: height) {
            return NSImage(cgImage: cgImage, size: .init(width: width, height: height))
        } else {
            return nil
        }
    }
}
