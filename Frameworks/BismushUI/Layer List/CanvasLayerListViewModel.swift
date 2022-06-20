//
//  CanvasLayerViewModel.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import BismushKit
import Foundation
import SwiftUI

public class CanvasLayerListViewModel: ObservableObject {
    private var store: BismushStore

    public init(store: BismushStore) {
        self.store = store
    }

    var layers: [CanvasLayer] {
        /*        store.canvasRender.layerRenderers.map { layer in
             layer.canvasLayer
         }*/
        []
    }

    func visible(index _: Int) -> Binding<Bool> {
        Binding(
            get: {
//                self.store.canvasRender.layerRenderers[index].visible
                true
            },
            set: { _ in
//                self.store.canvasRender.layerRenderers[index].visible = visible
//                self.objectWillChange.send()
            }
        )
    }

    func move(fromOffsets _: IndexSet, toOffset _: Int) {
//        store.canvasRender.layerRenderers.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}
