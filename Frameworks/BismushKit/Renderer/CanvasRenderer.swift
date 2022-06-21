//
//  CanvasRenderer.swift
//  Bismush
//
//  Created by mzp on 3/23/22.
//

import Foundation
import Metal
import simd
import SwiftUI

public class CanvasRenderer: ObservableObject {
    public struct Context {
        var encoder: MTLRenderCommandEncoder
        var viewPortSize: Size<ViewCoordinate>

        public init(encoder: MTLRenderCommandEncoder, viewPortSize: Size<ViewCoordinate>) {
            self.encoder = encoder
            self.viewPortSize = viewPortSize
        }
    }

    private let document: CanvasDocument
    private let layerRenderer: CanvasLayerRenderer

    public init(document: CanvasDocument) {
        self.document = document
        layerRenderer = CanvasLayerRenderer(document: document)
    }

    // MARK: - Render

    public func render(context: Context) {
        let context = CanvasLayerRenderer.Context(
            encoder: context.encoder,
            projection: document.canvas.projection(viewPortSize: context.viewPortSize) * document.canvas.modelViewMatrix
        )
        for layer in document.canvas.layers.reversed() {
            layerRenderer.render(canvasLayer: layer, context: context)
        }
    }
}
