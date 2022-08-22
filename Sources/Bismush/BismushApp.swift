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
        DocumentGroup(
            newDocument: {
                try! CanvasDocument()
            }, editor: { configuration in
                ViewModelProvider(document: configuration.document) {
                    WorkspaceView {
                        Artboard()
                    }
                }
                .navigationTitle("CanvasTest")
            }
        )
    }
}
