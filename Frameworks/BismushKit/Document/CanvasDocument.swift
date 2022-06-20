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
    static let kLayerContainerName = "Layers"

    struct Context: DataContext {
        var fileWrapper: FileWrapper?

        var layerContainer: FileWrapper? {
            fileWrapper?.fileWrappers?[CanvasDocument.kLayerContainerName]
        }

        func layer(id: String) -> Data? {
            layerContainer?.fileWrappers?["\(id).layerData"]?.regularFileContents
        }
    }

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
        artboard = ArtboardStore(canvas: canvas, dataContext: Context())
    }

    public required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.fileWrappers?["Info.json"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        canvas = try JSONDecoder().decode(Canvas.self, from: data)
        artboard = ArtboardStore(canvas: canvas, dataContext: Context(fileWrapper: configuration.file))
    }

    public func snapshot(contentType: UTType) throws -> CanvasDocument {
        assert(contentType.identifier == "jp.mzp.bismush.canvas")
        return self
    }

    public func fileWrapper(snapshot: CanvasDocument, configuration: WriteConfiguration) throws -> FileWrapper {
        let container = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])

        // MetaData
        let data = try JSONEncoder().encode(snapshot.canvas)
        container.addRegularFile(withContents: data, preferredFilename: "Info.json")

        // Data
        let layerContainer = FileWrapper(directoryWithFileWrappers: [:])
        layerContainer.preferredFilename = Self.kLayerContainerName
        for layer in snapshot.artboard.layers {
            layerContainer.addRegularFile(
                withContents: layer.data,
                preferredFilename: "\(layer.canvasLayer.id).layerData"
            )
        }
        container.addFileWrapper(layerContainer)

        return container
    }
}
