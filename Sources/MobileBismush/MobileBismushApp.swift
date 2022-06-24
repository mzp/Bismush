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
    var body: some Scene {
        DocumentGroup(
            newDocument: {
                CanvasDocument(canvas: .empty)
            }, editor: { configuration in
                ViewModelProvider(document: configuration.document) {
                    MobileWorkspaceView {
                        Artboard()
                    }
                }
            }
        )
    }
}
