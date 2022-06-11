//
//  CanvasLayerView.swift
//  Bismush
//
//  Created by mzp on 5/30/22.
//

import BismushKit
import SwiftUI

public struct CanvasLayerList: View {
    @EnvironmentObject var viewModel: CanvasLayerListViewModel

    public init() {}

    public var body: some View {
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
        CanvasLayerList().environmentObject(CanvasLayerListViewModel(store: BismushStore.makeSample()))
    }
}
