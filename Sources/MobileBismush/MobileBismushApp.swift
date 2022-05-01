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
        WindowGroup {
            MobileWorkspaceView {
                ContentView()
            }
            .environmentObject(MobileArtboardViewModel())
        }
    }
}
