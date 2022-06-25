//
//  ViewModelProvider.swift
//  MobileBismush
//
//  Created by mzp on 6/11/22.
//
import BismushKit
import BismushUI
import SwiftUI

struct ViewModelProvider<Content: View>: View {
    @ObservedObject var document: CanvasDocument
    var content: () -> Content
    var editor: BismushEditor

    init(document: CanvasDocument, content: @escaping () -> Content) {
        self.document = document
        editor = BismushEditor(document: document)
        self.content = content
    }

    var body: some View {
        content()
            .environmentObject(CanvasLayerListViewModel(editor: editor))
            .environmentObject(MobileArtboardViewModel(editor: editor))
    }
}

struct SampleViewModel<Content: View>: View {
    var content: () -> Content
    @StateObject var document: CanvasDocument = .sample
    var body: some View {
        ViewModelProvider(document: document) {
            content()
        }
    }
}
