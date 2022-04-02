//
//  CanvasRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/25/22.
//

import CoreGraphics
import Foundation
import Metal
import simd

class ArtboardRenderer {
    struct Context {
        var encoder: MTLRenderCommandEncoder
        var viewPortSize: Size<ViewCoordinate>
    }

    let store: ArtboardStore
    let layerRenderers: [ArtboardLayerRenderer]

    init(store: ArtboardStore) {
        self.store = store
        layerRenderers = store.layers.map { store in
            ArtboardLayerRenderer(store: store)
        }
    }

    func render(context: Context) {
        let context = ArtboardLayerRenderer.Context(
            encoder: context.encoder,
            projection: store.projection(viewPortSize: context.viewPortSize) * store.modelViewMatrix
        )
        for renderer in layerRenderers.reversed() {
            renderer.render(context: context)
        }
    }
}
