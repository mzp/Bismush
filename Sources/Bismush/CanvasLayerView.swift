//
//  CanvasLayerView.swift
//  Bismush
//
//  Created by mzp on 5/30/22.
//

import BismushKit
import SwiftUI

extension CanvasLayer: Identifiable {}

struct CanvasLayerView: View {
    @EnvironmentObject var viewModel: ArtboardViewModel
    @State var selection: CanvasLayer?
    var body: some View {
        VStack {
            List(viewModel.store.canvas.layers, selection: $selection) { layer in
                HStack {
                    Toggle(layer.name, isOn: .constant(true))
                }
            }
        }
    }
}

struct CanvasLayerView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasLayerView()
            .environmentObject(ArtboardViewModel())
    }
}
