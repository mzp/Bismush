//
//  CanvasLayerViewModel.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import BismushKit
import Foundation
import SwiftUI

public class CanvasLayerListViewModel: ObservableObject {
    private var editor: BismushEditor

    public init(editor: BismushEditor) {
        self.editor = editor
    }

    var layers: [CanvasLayer] {
        editor.document.canvas.layers
    }

    func visible(index: Int) -> Binding<Bool> {
        Binding(
            get: {
                self.editor.document.canvas.layers[index].visible
            },
            set: { visible in
                self.editor.document.canvas.layers[index].visible = visible
                self.objectWillChange.send()
            }
        )
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        editor.document.canvas.layers.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}
