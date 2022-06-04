//
//  CanvasLayerViewModel.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import BismushKit
import Foundation
import SwiftUI

class CanvasLayerListViewModel: ObservableObject {
    private var store: ArtboardStore

    init(store: ArtboardStore) {
        self.store = store
    }

    var layers: [CanvasLayer] {
        store.layers.map(\.canvasLayer)
    }

    func visible(index: Int) -> Binding<Bool> {
        Binding(
            get: {
                self.store.layers[index].visible
            },
            set: { visible in
                self.store.layers[index].visible = visible
                self.objectWillChange.send()
            }
        )
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        store.layers.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}
