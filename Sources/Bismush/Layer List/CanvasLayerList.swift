//
//  CanvasLayerView.swift
//  Bismush
//
//  Created by mzp on 5/30/22.
//

import BismushKit
import SwiftUI

struct CanvasLayerList: View {
    @EnvironmentObject var viewModel: CanvasLayerListViewModel
    var body: some View {
        List {
            ForEach(Array(viewModel.layers.enumerated()), id: \.1) { index, layer in
                HStack {
                    Toggle("Visible", isOn: viewModel.visible(index: index)).labelsHidden()
                    Text(layer.name)
                }
            }.onMove(perform: { fromOffsets, toOffset in
                viewModel.move(fromOffsets: fromOffsets, toOffset: toOffset)
            })
        }
    }
}

struct CanvasLayerList_Previews: PreviewProvider {
    static var previews: some View {
        SampleViewModel {
            CanvasLayerList()
        }
    }
}
