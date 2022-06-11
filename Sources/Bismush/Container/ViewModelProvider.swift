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
    var bismushStore: BismushStore

    var content: () -> Content
    var body: some View {
        content()
            .environmentObject(ArtboardViewModel(store: bismushStore))
            .environmentObject(RGBColorViewModel(store: bismushStore))
            .environmentObject(CanvasLayerListViewModel(store: bismushStore))
    }
}

struct SampleViewModel<Content: View>: View {
    @StateObject var store = BismushStore.makeSample()
    var content: () -> Content

    var body: some View {
        ViewModelProvider(bismushStore: store) {
            content()
        }
    }
}
