//
//  ContentView.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import BismushKit
import SwiftUI

struct ContentView: View {
    @State var store: ArtboardStore
    let stroke: Brush

    init(store: ArtboardStore) {
        self.store = store
        stroke = Brush(store: store)
    }

    var body: some View {
        MobileArtboard(store: store)
            .onTouchesEnded(perform: { _, _, _ in stroke.clear() })
            .onTouchesMoved(perform: touchesMoved(_:with:in:))
            .edgesIgnoringSafeArea(.all)
    }

    func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?, in view: UIView) {
        BismushLogger.mobile.info("Touches moved: \(touches.debugDescription)")
        if let touch = touches.first {
            let location = touch.location(in: view)
            let point = Point<ViewCoordinate>(
                x: Float(location.x),
                y: Float(view.frame.size.height - location.y)
            )
            let inputEvent = PenInputEvent(point: point, pressure: Float(touch.force))
            stroke.add(inputEvent: inputEvent, viewSize: Size(cgSize: view.frame.size))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: ArtboardStore.makeSample())
    }
}
