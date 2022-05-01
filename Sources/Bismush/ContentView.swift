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
    @EnvironmentObject var viewModel: ArtboardViewModel
    var body: some View {
        DesktopArtboard(store: viewModel.store)
            .onMouseDragged(perform: mouseDragged(with:in:))
            .onMouseUp(perform: { _, _ in viewModel.brush.clear() })
            .frame(width: 800, height: 800, alignment: .center)
    }

    func mouseDragged(with event: NSEvent, in view: NSView) {
        BismushLogger.desktop.trace("Mouse dragged \(event.debugDescription)")
        let location = view.convert(event.locationInWindow, from: nil)
        let point = Point<ViewCoordinate>(cgPoint: location)
        BismushLogger.desktop.trace("\(event.locationInWindow.debugDescription) -> (\(point.x), \(point.y))")
        viewModel.brush.add(
            pressurePoint: .init(point: point, pressure: event.pressure),
            viewSize: Size(cgSize: view.frame.size)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ArtboardViewModel())
    }
}
