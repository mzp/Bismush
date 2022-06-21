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
        get { editor.brush.color.nsColor }
        set {
            objectWillChange.send()
            editor.brush.color = BismushColor(cgColor: newValue.cgColor)
        }
    }

    private let editor: BismushEditor

    init(editor: BismushEditor) {
        self.editor = editor
        red = Float(editor.brush.color.red)
        green = Float(editor.brush.color.green)
        blue = Float(editor.brush.color.blue)
        alpha = Float(editor.brush.color.alpha)
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
