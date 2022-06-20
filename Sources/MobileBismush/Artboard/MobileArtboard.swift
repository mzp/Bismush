//
//  MobileArtboard.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/22/22.
//

import BismushKit
import SwiftUI
import UIKit

protocol MobileArtboardDelegate: AnyObject {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
}

class MobileArtboardView: ArtboardView {
    weak var artboardDelegate: MobileArtboardDelegate?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        artboardDelegate?.touchesBegan(touches, with: event, in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        artboardDelegate?.touchesMoved(touches, with: event, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        artboardDelegate?.touchesEnded(touches, with: event, in: self)
    }
}

struct MobileArtboard: UIViewRepresentable {
    var store: CanvasRenderer

    var onTouchesBegan: ((Set<UITouch>, UIEvent?, UIView) -> Void)?
    var onTouchesMoved: ((Set<UITouch>, UIEvent?, UIView) -> Void)?
    var onTouchesEnded: ((Set<UITouch>, UIEvent?, UIView) -> Void)?

    func makeUIView(context: Context) -> MobileArtboardView {
        let view = MobileArtboardView(store: store)
        view.artboardDelegate = context.coordinator
        return view
    }

    func updateUIView(_: MobileArtboardView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func onTouchesBegan(perform: @escaping (Set<UITouch>, UIEvent?, UIView) -> Void) -> MobileArtboard {
        var that = self
        that.onTouchesBegan = perform
        return that
    }

    func onTouchesMoved(perform: @escaping (Set<UITouch>, UIEvent?, UIView) -> Void) -> MobileArtboard {
        var that = self
        that.onTouchesMoved = perform
        return that
    }

    func onTouchesEnded(perform: @escaping (Set<UITouch>, UIEvent?, UIView) -> Void) -> MobileArtboard {
        var that = self
        that.onTouchesEnded = perform
        return that
    }

    class Coordinator: MobileArtboardDelegate {
        private let parent: MobileArtboard

        init(parent: MobileArtboard) {
            self.parent = parent
        }

        func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
            parent.onTouchesBegan?(touches, event, view)
        }

        func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
            parent.onTouchesMoved?(touches, event, view)
        }

        func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
            parent.onTouchesEnded?(touches, event, view)
        }
    }
}
