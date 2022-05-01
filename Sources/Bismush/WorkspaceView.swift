//
//  WorkspaceView.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import SwiftUI

struct Pallet: View {
    @EnvironmentObject var viewModel: ArtboardViewModel
    var color: NSColor

    var body: some View {
        Button(
            action: {
                viewModel.brushColor = Color(nsColor: color)
            },
            label: {
                Color(nsColor: color).frame(width: 16, height: 16)
            }
        )
    }
}

struct WorkspaceView<Content: View>: View {
    @EnvironmentObject var viewModel: ArtboardViewModel

    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationView {
            List {
                Section("Color") {
                    HStack {
                        Pallet(color: .red)
                        Pallet(color: .yellow)
                        Pallet(color: .cyan)
                    }
                    HStack {
                        Pallet(color: .white)
                        Pallet(color: .black)
                    }
                }
            }
            content()
        }
    }
}

struct WorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceView {
            Color.red.frame(width: 100, height: 100)
        }
    }
}
