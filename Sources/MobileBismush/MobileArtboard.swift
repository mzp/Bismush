//
//  MobileArtboard.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/22/22.
//

import BismushKit
import SwiftUI
import UIKit

protocol ArtboardDelegate: AnyObject {
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
}

class MobileArtboardView: ArtboardView {
    weak var artboardDelegate: ArtboardDelegate?

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        artboardDelegate?.touchesMoved(touches, with: event, in: self)
    }
}

struct MobileArtboard: UIViewRepresentable {
    var store: ArtboardStore

    var onTouchesMoved: ((Set<UITouch>, UIEvent?, UIView) -> Void)?
    func makeUIView(context: Context) -> MobileArtboardView {
        let view = MobileArtboardView(store: store)
        view.artboardDelegate = context.coordinator
        return view
    }

    func updateUIView(_: MobileArtboardView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func onTouchesMoved(perform: @escaping (Set<UITouch>, UIEvent?, UIView) -> Void) -> MobileArtboard {
        var that = self
        that.onTouchesMoved = perform
        return that
    }

    class Coordinator: ArtboardDelegate {
        private let parent: MobileArtboard

        init(parent: MobileArtboard) {
            self.parent = parent
        }

        func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
            parent.onTouchesMoved?(touches, event, view)
        }
    }
}
