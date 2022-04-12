//
//  ContentView.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import AppKit
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
        DesktopArtboard(store: store)
            .onMouseDragged(perform: mouseDragged(with:in:))
            .onMouseUp(perform: { _, _ in stroke.clear() })
            .frame(width: 800, height: 800, alignment: .center)
    }

    func mouseDragged(with event: NSEvent, in view: NSView) {
        BismushLogger.desktop.debug("Mouse dragged at \(event.locationInWindow.debugDescription)")
        stroke.add(
            point: Point(cgPoint: event.locationInWindow),
            viewSize: Size(cgSize: view.frame.size)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: ArtboardStore.makeSample())
    }
}
