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
            ContentView(store: ArtboardStore.makeSample())
                .navigationTitle("CanvasTest")
        }
    }
}
