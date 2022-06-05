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
    var bismushStore = BismushStore()

    var body: some Scene {
        WindowGroup {
            WorkspaceView {
                Artboard(viewModel: ArtboardViewModel(store: bismushStore))
            }
            .navigationTitle("CanvasTest")
            .environmentObject(bismushStore)
        }
    }
}
