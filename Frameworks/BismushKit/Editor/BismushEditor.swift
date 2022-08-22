//
//  BismushStore.swift
//  Bismush
//
//  Created by Hiro Mizuno on 6/4/22.
//

import Foundation
import SwiftUI

public class BismushEditor: ObservableObject {
    public let document: CanvasDocument
    public let canvasRender: CanvasRenderer
    public let brush: Brush

    public init(document: CanvasDocument) {
        self.document = document
        canvasRender = CanvasRenderer(document: document, pixelFormat: document.activeLayer.pixelFormat, rasterSampleCount: document.rasterSampleCount)
        brush = Brush(document: document)
    }

    public func getSnapshot() -> CanvasDocumentSnapshot {
        document.snapshot()
    }

    public func restore(snapshot: CanvasDocumentSnapshot) {
        document.restore(snapshot: snapshot)
    }

    public class func makeSample() -> BismushEditor {
        BismushEditor(document: .sample)
    }
}
