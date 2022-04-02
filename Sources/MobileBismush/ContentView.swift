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
    let stroke: StrokeAction

    init(store: ArtboardStore) {
        self.store = store
        stroke = StrokeAction(store: store)
    }

    var body: some View {
        MobileArtboard(store: store)
            .onTouchesMoved(perform: touchesMoved(_:with:in:))
            .edgesIgnoringSafeArea(.all)
    }

    func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?, in view: UIView) {
        let locations = touches.map { $0.location(in: view) }
        BismushLogger.mobile.info("Touch moved at \(locations.debugDescription)")

        for location in locations {
            let location = Point<ViewCoordinate>(
                x: Float(location.x),
                y: Float(view.frame.size.height - location.y)
            )
            stroke.add(point: location, viewSize: Size(cgSize: view.frame.size))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: ArtboardStore.makeSample())
    }
}
