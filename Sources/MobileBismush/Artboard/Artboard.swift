//
//  ContentView.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import BismushKit
import SwiftUI

struct Artboard: View {
    @EnvironmentObject var viewModel: MobileArtboardViewModel

    var body: some View {
        MobileArtboard(document: viewModel.editor.document)
            .onTouchesEnded(perform: { _, _, _ in viewModel.brush.clear() })
            .onTouchesMoved(perform: touchesMoved(_:with:in:))
            .edgesIgnoringSafeArea(.all)
    }

    func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?, in view: UIView) {
        BismushLogger.mobile.trace("Touches moved: \(touches.debugDescription)")
        if let touch = touches.first {
            let location = touch.location(in: view)
            let point = Point<ViewCoordinate>(
                x: Float(location.x),
                y: Float(view.frame.size.height - location.y)
            )
            let force: Float
            if touch.type == .pencil {
                force = Float(touch.force)
            } else {
                // Finger tap event doesn't have force value
                force = 1
            }
            let pressurePoint = PressurePoint(point: point, pressure: force)
            viewModel.brush.add(pressurePoint: pressurePoint, viewSize: Size(cgSize: view.frame.size))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SampleViewModel {
            Artboard()
        }
    }
}
