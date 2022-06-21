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
    let editor: BismushEditor
    var brush: Brush {
        editor.brush
    }

    init(editor: BismushEditor) {
        self.editor = editor
    }
}
