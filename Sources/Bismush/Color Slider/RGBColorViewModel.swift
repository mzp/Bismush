//
//  ColorSliderViewModel.swift
//  Bismush
//
//  Created by mzp on 5/15/22.
//

import Foundation
import SwiftUI

class RGBColorViewModel: ObservableObject {
    var currentColor: NSColor {
        NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }

    @Binding var color: NSColor

    init(color: Binding<NSColor>) {
        _color = color
        red = Float(color.wrappedValue.redComponent)
        green = Float(color.wrappedValue.greenComponent)
        blue = Float(color.wrappedValue.blueComponent)
        alpha = Float(color.wrappedValue.alphaComponent)
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
