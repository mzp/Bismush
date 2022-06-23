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
    @ObservedObject var editor: BismushEditor

    var content: () -> Content
    var body: some View {
        content()
            .environmentObject(CanvasLayerListViewModel(editor: editor))
            .environmentObject(MobileArtboardViewModel(editor: editor))
    }
}

struct SampleViewModel<Content: View>: View {
    var content: () -> Content
    @StateObject var editor = BismushEditor.makeSample()
    var body: some View {
        ViewModelProvider(editor: editor) {
            content()
        }
    }
}
