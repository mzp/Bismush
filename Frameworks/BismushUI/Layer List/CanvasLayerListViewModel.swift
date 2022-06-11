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
        store.artboard.layers.map(\.canvasLayer)
    }

    func visible(index: Int) -> Binding<Bool> {
        Binding(
            get: {
                self.store.artboard.layers[index].visible
            },
            set: { visible in
                self.store.artboard.layers[index].visible = visible
                self.objectWillChange.send()
            }
        )
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        store.artboard.layers.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}
