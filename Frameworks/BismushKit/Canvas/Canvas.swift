//
//  Canvas.swift
//  Bismush
//
//  Created by mzp on 3/15/22.
//

import Foundation
import SwiftUI

#if os(iOS)
    public struct Canvas: UIViewRepresentable {
        public init() {}

        public func makeUIView(context _: Context) -> CanvasMetalView {
            CanvasMetalView()
        }

        public func updateUIView(_: CanvasMetalView, context _: Context) {}
    }
#else
    public struct Canvas: NSViewRepresentable {
        public init() {}

        public func makeNSView(context _: Context) -> CanvasMetalView {
            CanvasMetalView()
        }

        public func updateNSView(_: CanvasMetalView, context _: Context) {}
    }
#endif
