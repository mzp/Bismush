//
//  ArtboardViewModel.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import BismushKit
import Foundation
import SwiftUI

class ArtboardViewModel: ObservableObject {
    let store: BismushStore
    var brush: Brush {
        store.brush
    }

    init(store: BismushStore) {
        self.store = store
    }
}
