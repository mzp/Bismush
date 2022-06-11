//
//  WorkspaceView.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import BismushUI
import SwiftUI

struct Pallet: View {
    @EnvironmentObject var viewModel: MobileArtboardViewModel
    var color: UIColor

    var body: some View {
        Button(
            action: {
                viewModel.brushColor = Color(uiColor: color)
            },
            label: {
                Color(uiColor: color).frame(width: 16, height: 16)
            }
        )
    }
}

struct MobileWorkspaceView<Content: View>: View {
    @EnvironmentObject var viewModel: MobileArtboardViewModel

    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Section("Color") {
                    Pallet(color: .red)
                    Pallet(color: .yellow)
                    Pallet(color: .cyan)
                    Pallet(color: .white)
                    Pallet(color: .black)
                }
                Section("Layer") {
                    CanvasLayerList()
                }
            }.frame(width: 250)
            content()
        }
    }
}

struct MobileWorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        MobileWorkspaceView {
            Color.red.frame(width: 100, height: 100)
        }
    }
}
