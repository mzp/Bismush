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
    let store: ArtboardStore
    let brush: Brush

    @Published var brushColor: NSColor {
        didSet {
            brush.color = BismushColor(cgColor: brushColor.cgColor)
        }
    }

    init() {
        store = ArtboardStore.makeSample()
        brush = Brush(store: store)
        brushColor = brush.color.nsColor
    }
}
