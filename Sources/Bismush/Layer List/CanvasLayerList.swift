//
//  CanvasLayerView.swift
//  Bismush
//
//  Created by mzp on 5/30/22.
//

import BismushKit
import SwiftUI

struct CanvasLayerList: View {
    var viewModel: CanvasLayerListViewModel

    @State var selection: String?
    var body: some View {
        VStack {
            Table(viewModel.layers, selection: $selection) {
                TableColumn("Visible") { layer in
                    Toggle("Visibe", isOn: .constant(layer.visible)).labelsHidden()
                }
                TableColumn("Name", value: \.name)
            }
        }
    }
}

struct CanvasLayerListPreview: PreviewProvider {
    static var previews: some View {
        CanvasLayerList(viewModel: .init(store: ArtboardStore.makeSample()))
    }
}
