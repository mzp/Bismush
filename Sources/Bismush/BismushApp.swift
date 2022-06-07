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
    var body: some Scene {
        WindowGroup {
            BismushViewModelProvider(bismushStore: BismushStore.makeSample()) {
                WorkspaceView {
                    Artboard()
                }
            }
            .navigationTitle("CanvasTest")
        }
    }
}
