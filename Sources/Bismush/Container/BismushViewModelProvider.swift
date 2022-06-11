//
//  BismushViewModelProvider.swift
//  Bismush
//
//  Created by mzp on 6/6/22.
//

import BismushKit
import SwiftUI

struct BismushViewModelProvider<Content: View>: View {
    var bismushStore: BismushStore

    var content: () -> Content
    var body: some View {
        Group {
            content()
        }
        .environmentObject(ArtboardViewModel(store: bismushStore))
        .environmentObject(RGBColorViewModel(store: bismushStore))
        .environmentObject(CanvasLayerListViewModel(store: bismushStore))
    }
}

struct SampleViewModel<Content: View>: View {
    var content: () -> Content

    var body: some View {
        BismushViewModelProvider(bismushStore: BismushStore.makeSample()) {
            content()
        }
    }
}
