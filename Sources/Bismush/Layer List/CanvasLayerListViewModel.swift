//
//  CanvasLayerViewModel.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import BismushKit
import Foundation
import SwiftUI

class CanvasLayerListViewModel {
    @Published var layers: [CanvasLayer]
    private let store: ArtboardStore

    init(store: ArtboardStore) {
        self.store = store
        layers = store.canvas.layers
    }
}
