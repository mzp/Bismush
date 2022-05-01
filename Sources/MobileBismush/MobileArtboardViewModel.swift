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
    let store: ArtboardStore
    let brush: Brush

    init() {
        store = ArtboardStore.makeSample()
        brush = Brush(store: store)
    }

    var brushColor: Color {
        get {
            let color = brush.color
            return Color(
                red: Double(color.red),
                green: Double(color.green),
                blue: Double(color.blue),
                opacity: Double(color.alpha)
            )
        }
        set {
            brush.color = BismushColor(cgColor: newValue.cgColor!)
        }
    }
}
