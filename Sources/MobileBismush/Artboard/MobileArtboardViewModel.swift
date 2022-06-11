//
//  ArtboardViewModel.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import BismushKit
import Foundation
import SwiftUI

class MobileArtboardViewModel: ObservableObject {
    let store: BismushStore

    init(store: BismushStore) {
        self.store = store
    }

    var brush: Brush { store.brush }

    var brushColor: Color {
        get {
            let color = store.brush.color
            return Color(
                red: Double(color.red),
                green: Double(color.green),
                blue: Double(color.blue),
                opacity: Double(color.alpha)
            )
        }
        set {
            store.brush.color = BismushColor(cgColor: newValue.cgColor!)
        }
    }
}
