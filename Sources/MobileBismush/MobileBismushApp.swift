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
    @StateObject var editor = BismushEditor.makeSample()

    var body: some Scene {
        WindowGroup {
            ViewModelProvider(editor: editor) {
                MobileWorkspaceView {
                    Artboard()
                }
            }
            .environmentObject(editor)
        }
    }
}
