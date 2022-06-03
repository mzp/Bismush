//
//  WorkspaceView.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import SwiftUI

struct WorkspaceView<Content: View>: View {
    @EnvironmentObject var viewModel: ArtboardViewModel

    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack {
            List {
                Section("Color") {
                    Color(nsColor: viewModel.brushColor).frame(width: 16, height: 16)
                    RGBSlider(color: $viewModel.brushColor)
                }
                Section("Layer") {
                    CanvasLayerView()
                }.frame(height: 100, alignment: .topLeading)
            }.frame(width: 400)
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
