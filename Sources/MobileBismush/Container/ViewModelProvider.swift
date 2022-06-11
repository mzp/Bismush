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
    var bismushStore: BismushStore

    var content: () -> Content
    var body: some View {
        content()
            .environmentObject(CanvasLayerListViewModel(store: bismushStore))
            .environmentObject(MobileArtboardViewModel(store: bismushStore))
    }
}

struct SampleViewModel<Content: View>: View {
    var content: () -> Content
    @StateObject var store = BismushStore.makeSample()
    var body: some View {
        ViewModelProvider(bismushStore: store) {
            content()
        }
    }
}
