//
//  ArtboardMacOS.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/22/22.
//

import AppKit
import BismushKit
import SwiftUI

protocol DesktopArtboardDelegate: AnyObject {
    func mouseUp(with event: NSEvent, in view: NSView)
    func mouseDragged(with event: NSEvent, in view: NSView)
    func mouseDown(with event: NSEvent, in view: NSView)
}

class DesktopArtboardView: ArtboardView {
    weak var artboardDelegate: DesktopArtboardDelegate?

    override func mouseDragged(with event: NSEvent) {
        artboardDelegate?.mouseDragged(with: event, in: self)
    }

    override func mouseDown(with event: NSEvent) {
        artboardDelegate?.mouseDown(with: event, in: self)
    }

    override func mouseUp(with event: NSEvent) {
        artboardDelegate?.mouseUp(with: event, in: self)
    }
}

struct DesktopArtboard: NSViewRepresentable {
    var store: ArtboardStore
    var onMouseDown: ((NSEvent, NSView) -> Void)?
    var onMouseDragged: ((NSEvent, NSView) -> Void)?
    var onMouseUp: ((NSEvent, NSView) -> Void)?

    func makeNSView(context: Context) -> DesktopArtboardView {
        let view = DesktopArtboardView(store: store)
        view.artboardDelegate = context.coordinator
        return view
    }

    func updateNSView(_: DesktopArtboardView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func onMouseDown(perform: @escaping (NSEvent, NSView) -> Void) -> DesktopArtboard {
        var that = self
        that.onMouseDown = perform
        return that
    }

    func onMouseDragged(perform: @escaping (NSEvent, NSView) -> Void) -> DesktopArtboard {
        var that = self
        that.onMouseDragged = perform
        return that
    }

    func onMouseUp(perform: @escaping (NSEvent, NSView) -> Void) -> DesktopArtboard {
        var that = self
        that.onMouseUp = perform
        return that
    }

    class Coordinator: DesktopArtboardDelegate {
        private let parent: DesktopArtboard

        init(parent: DesktopArtboard) {
            self.parent = parent
        }

        func mouseDragged(with event: NSEvent, in view: NSView) {
            parent.onMouseDragged?(event, view)
        }

        func mouseDown(with event: NSEvent, in view: NSView) {
            parent.onMouseDown?(event, view)
        }

        func mouseUp(with event: NSEvent, in view: NSView) {
            parent.onMouseUp?(event, view)
        }
    }
}
