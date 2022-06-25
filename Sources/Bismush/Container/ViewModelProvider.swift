//
//  BismushViewModelProvider.swift
//  Bismush
//
//  Created by mzp on 6/6/22.
//

import BismushKit
import BismushUI
import SwiftUI

struct ViewModelProvider<Content: View>: View {
    @ObservedObject var document: CanvasDocument
    var editor: BismushEditor

    init(document: CanvasDocument, content: @escaping () -> Content) {
        self.document = document
        editor = BismushEditor(document: document)
        self.content = content
    }

    var content: () -> Content
    var body: some View {
        content()
            .environmentObject(ArtboardViewModel(editor: editor))
            .environmentObject(RGBColorViewModel(editor: editor))
            .environmentObject(CanvasLayerListViewModel(editor: editor))
    }
}

struct SampleViewModel<Content: View>: View {
    @StateObject var document = CanvasDocument.sample
    var content: () -> Content

    var body: some View {
        ViewModelProvider(document: document) {
            content()
        }
    }
}
