//
//  BismushApp.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import BismushKit
import SwiftUI

@main
struct BismushApp: App {
    let artboardStore = ArtboardStore.makeSample()

    var body: some Scene {
        WindowGroup {
            WorkspaceView {
                ContentView()
            }
            .navigationTitle("CanvasTest")
            .environmentObject(ArtboardViewModel(store: artboardStore))
            .environmentObject(artboardStore)
        }
    }
}
