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
        store.document.canvas.layers
    }

    func visible(index: Int) -> Binding<Bool> {
        Binding(
            get: {
                self.store.document.canvas.layers[index].visible
            },
            set: { visible in
                self.store.document.canvas.layers[index].visible = visible
                self.objectWillChange.send()
            }
        )
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        store.document.canvas.layers.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}
