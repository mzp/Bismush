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
    let editor: BismushEditor

    init(editor: BismushEditor) {
        self.editor = editor
    }

    var brush: Brush { editor.brush }

    var brushColor: Color {
        get {
            let color = editor.brush.color
            return Color(
                red: Double(color.red),
                green: Double(color.green),
                blue: Double(color.blue),
                opacity: Double(color.alpha)
            )
        }
        set {
            editor.brush.color = BismushColor(cgColor: newValue.cgColor!)
        }
    }
}
