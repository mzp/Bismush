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
    @StateObject var store = BismushStore.makeSample()
    var body: some Scene {
        WindowGroup {
            ViewModelProvider(bismushStore: store) {
                WorkspaceView {
                    Artboard()
                }
            }
            .navigationTitle("CanvasTest")
        }
    }
}
