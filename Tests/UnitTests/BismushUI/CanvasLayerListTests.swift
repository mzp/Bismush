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
    private let editor: BismushEditor = .makeSample()
    private var viewModel: CanvasLayerListViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = CanvasLayerListViewModel(editor: editor)
    }

    func testLayers() throws {
        XCTAssertEqual(viewModel.layers.count, editor.document.canvas.layers.count)
    }

    func testVisible() {
        @Binding var visible: Bool
        _visible = viewModel.visible(index: 0)
        XCTAssertTrue(visible)
        visible.toggle()
        XCTAssertFalse(editor.document.canvas.layers[0].visible)
    }

    func testMove() {
        viewModel.move(fromOffsets: [0], toOffset: 2)
        XCTAssertEqual("#2", editor.document.canvas.layers[0].name)
        XCTAssertEqual("#1", editor.document.canvas.layers[1].name)
    }
}
