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
    var bismushStore: BismushStore

    init(document: CanvasDocument, content: @escaping () -> Content) {
        self.document = document
        bismushStore = BismushStore(document: document)
        self.content = content
    }

    var content: () -> Content
    var body: some View {
        content()
            .environmentObject(ArtboardViewModel(store: bismushStore))
            .environmentObject(RGBColorViewModel(store: bismushStore))
            .environmentObject(CanvasLayerListViewModel(store: bismushStore))
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
