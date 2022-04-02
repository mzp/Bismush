//
//  ArtboardMacOS.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/22/22.
//

import AppKit
import BismushKit
import SwiftUI

protocol ArtboardDelegate: AnyObject {
    func mouseDragged(with event: NSEvent, in view: NSView)
}

class DesktopArtboardView: ArtboardView {
    weak var artboardDelegate: ArtboardDelegate?

    override func mouseDragged(with event: NSEvent) {
        artboardDelegate?.mouseDragged(with: event, in: self)
    }
}

struct DesktopArtboard: NSViewRepresentable {
    var store: ArtboardStore
    var onMouseDragged: ((NSEvent, NSView) -> Void)?

    func makeNSView(context: Context) -> DesktopArtboardView {
        let view = DesktopArtboardView(store: store)
        view.artboardDelegate = context.coordinator
        return view
    }

    func updateNSView(_: DesktopArtboardView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func onMouseDragged(perform: @escaping (NSEvent, NSView) -> Void) -> DesktopArtboard {
        var that = self
        that.onMouseDragged = perform
        return that
    }

    class Coordinator: ArtboardDelegate {
        private let parent: DesktopArtboard

        init(parent: DesktopArtboard) {
            self.parent = parent
        }

        func mouseDragged(with event: NSEvent, in view: NSView) {
            parent.onMouseDragged?(event, view)
        }
    }
}
