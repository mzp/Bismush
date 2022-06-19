//
//  CanvasDocument.swift
//  Bismush
//
//  Created by mzp on 6/19/22.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let canvas = UTType(exportedAs: "jp.mzp.bismush.canvas")
}

public class CanvasDocument: ReferenceFileDocument {
    private let canvas: Canvas
    public let artboard: ArtboardStore

    public static var readableContentTypes: [UTType] {
        [.canvas]
    }

    public static var writableContentTypes: [UTType] {
        [.canvas]
    }

    public static let sample = CanvasDocument()

    public init(canvas: Canvas = .sample) {
        self.canvas = canvas
        artboard = ArtboardStore(canvas: canvas)
    }

    public required init(configuration _: ReadConfiguration) throws {
        canvas = .sample
        artboard = ArtboardStore(canvas: canvas)
    }

    public func snapshot(contentType _: UTType) throws -> CanvasDocument {
//        assert(contentType.identifier == "jp.mzp.bismush.canvas")
        // TODO: Create snapshot
        self
    }

    public func fileWrapper(snapshot: CanvasDocument, configuration _: WriteConfiguration) throws -> FileWrapper {
        let container = FileWrapper(directoryWithFileWrappers: [:])

        // MetaData
        let data = try JSONEncoder().encode(snapshot.canvas)
        container.addRegularFile(withContents: data, preferredFilename: "Info.json")

        // Data
        let layerContainer = FileWrapper(directoryWithFileWrappers: [:])
        for layer in snapshot.artboard.layers {
            layerContainer.addRegularFile(withContents: layer.data, preferredFilename: "\(layer.canvasLayer.id).layerData")
        }
        container.addFileWrapper(layerContainer)

        return container
    }
}
