//
//  ColorSliderViewModel.swift
//  Bismush
//
//  Created by mzp on 5/15/22.
//

import BismushKit
import Foundation
import SwiftUI

class RGBColorViewModel: ObservableObject {
    var currentColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }

    var color: NSColor {
        get { store.brush.color.nsColor }
        set {
            objectWillChange.send()
            store.brush.color = BismushColor(cgColor: newValue.cgColor)
        }
    }

    private let store: BismushStore

    init(store: BismushStore) {
        self.store = store
        red = Float(store.brush.color.red)
        green = Float(store.brush.color.green)
        blue = Float(store.brush.color.blue)
        alpha = Float(store.brush.color.alpha)
    }

    @Published var red: Float {
        didSet {
            color = currentColor
        }
    }

    @Published var green: Float {
        didSet {
            color = currentColor
        }
    }

    @Published var blue: Float {
        didSet {
            color = currentColor
        }
    }

    @Published var alpha: Float {
        didSet {
            color = currentColor
        }
    }
}
