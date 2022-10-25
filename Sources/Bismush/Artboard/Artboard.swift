//
//  Artboard.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import AppKit
import BismushKit
import SwiftUI

struct Artboard: View {
    @EnvironmentObject var viewModel: ArtboardViewModel

    @Environment(\.undoManager) var undoManagerInEnv
    @State var undoManager: UndoManager?

    var body: some View {
        DesktopArtboard(document: viewModel.editor.document)
            .onMouseDown(perform: mouseDown(with:in:))
            .onMouseDragged(perform: mouseDragged(with:in:))
            .onMouseUp(perform: mouseUp(with:in:))
            .onChange(of: self.undoManagerInEnv) {
                // XXX: why can't use \.undoManager directly?
                self.undoManager = $0
            }
            .frame(width: 800, height: 800, alignment: .center)
    }

    func mouseDown(with _: NSEvent, in _: NSView) {
        var scope = Activity("✍️\(#function)").enter()
        defer { scope.leave() }
        let snapshot = viewModel.editor.getSnapshot()
        undoManager?.registerUndo(withTarget: viewModel.editor, handler: { store in
            let redoSnapshot = store.getSnapshot()
            store.restore(snapshot: snapshot)
            undoManager?.registerUndo(withTarget: store, handler: { store in
                store.restore(snapshot: redoSnapshot)
            })
        })
    }

    func mouseDragged(with event: NSEvent, in view: NSView) {
        var scope = Activity("✍️\(#function)").enter()
        defer { scope.leave() }
        BismushLogger.desktop.trace("Mouse dragged \(event.debugDescription)")
        let location = view.convert(event.locationInWindow, from: nil)
        let point = Point<ViewCoordinate>(cgPoint: location)
        BismushLogger.desktop.trace("\(event.locationInWindow.debugDescription) -> (\(point.x), \(point.y))")
        viewModel.brush.viewSize = .init(width: 800, height: 800)
        viewModel.brush.add(
            pressurePoint: .init(point: point, pressure: event.pressure)
        )
    }

    func mouseUp(with _: NSEvent, in _: NSView) {
        var scope = Activity("✍️\(#function)").enter()
        defer { scope.leave() }
        viewModel.brush.commit()
    }
}

struct ArtboardPreviews: PreviewProvider {
    static var previews: some View {
        SampleViewModel {
            Artboard()
        }
    }
}
