//
//  WorkspaceView.swift
//  Bismush
//
//  Created by mzp on 4/24/22.
//

import BismushKit
import SwiftUI

struct WorkspaceView<Content: View>: View {
    @EnvironmentObject var store: BismushStore

    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Section("Color") {
                    RGBSlider(viewModel: .init(store: store))
                }
                Section("Layer") {
                    CanvasLayerList(viewModel: .init(store: store))
                }
            }
            .frame(width: 200)
            .padding()
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
