//
//  MobileBismushApp.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import BismushKit
import SwiftUI

@main
struct MobileBismushApp: App {
    @StateObject var store = BismushEditor.makeSample()

    var body: some Scene {
        WindowGroup {
            ViewModelProvider(bismushStore: store) {
                MobileWorkspaceView {
                    Artboard()
                }
            }
            .environmentObject(store)
        }
    }
}
