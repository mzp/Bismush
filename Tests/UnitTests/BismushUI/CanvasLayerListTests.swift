//
//  CanvasLayerListTests.swift
//  BismushKit_UnitTests_iOS
//
//  Created by mzp on 6/6/22.
//

import BismushKit
import SwiftUI
import XCTest
@testable import BismushUI

class CanvasLayerListTests: XCTestCase {
    private let store = BismushStore()
    private var viewModel: CanvasLayerListViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = CanvasLayerListViewModel(store: store)
    }

    func testLayers() throws {
        XCTAssertEqual(viewModel.layers.count, store.artboard.layers.count)
    }

    func testVisible() {
        @Binding var visible: Bool
        _visible = viewModel.visible(index: 0)
        XCTAssertTrue(visible)
        visible.toggle()
        XCTAssertFalse(store.artboard.layers[0].visible)
    }

    func testMove() {
        viewModel.move(fromOffsets: [0], toOffset: 2)
        XCTAssertEqual("#2", store.artboard.layers[0].canvasLayer.name)
        XCTAssertEqual("#1", store.artboard.layers[1].canvasLayer.name)
    }
}
