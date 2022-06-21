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

public class CanvasDocument: ReferenceFileDocument, LayerTextureContext {
    static let kLayerContainerName = "Layers"
    public var canvas: Canvas
    private let file: FileWrapper?

    public static let sample = CanvasDocument()

    public init(canvas: Canvas = .sample) {
        self.canvas = canvas
        file = nil
    }

    // MARK: - ReferenceFileDocument

    public static var readableContentTypes: [UTType] {
        [.canvas]
    }

    public static var writableContentTypes: [UTType] {
        [.canvas]
    }

    public required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.fileWrappers?["Info.json"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        canvas = try JSONDecoder().decode(Canvas.self, from: data)
        file = configuration.file
    }

    public func snapshot(contentType: UTType) throws -> CanvasDocumentSnapshot {
        assert(contentType.identifier == "jp.mzp.bismush.canvas")
        return snapshot()
    }

    public func fileWrapper(snapshot: CanvasDocumentSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let container = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])

        // MetaData
        let data = try JSONEncoder().encode(snapshot.canvas)
        container.addRegularFile(withContents: data, preferredFilename: "Info.json")

        // Data
        let layerContainer = FileWrapper(directoryWithFileWrappers: [:])
        layerContainer.preferredFilename = Self.kLayerContainerName

        for texture in snapshot.textures {
            let id = texture.canvasLayer.id
            layerContainer.addRegularFile(
                withContents: texture.texture.bmkData,
                preferredFilename: "\(id).texture"
            )

            if let data = texture.msaaTexture?.bmkData {
                layerContainer.addRegularFile(
                    withContents: data,
                    preferredFilename: "\(id).msaatexture"
                )
            }
        }
        container.addFileWrapper(layerContainer)

        return container
    }

    // MARK: - Snapshot

    func snapshot() -> CanvasDocumentSnapshot {
        .init(
            canvas: canvas,
            textures: textures.values.map { $0.copyOnWrite() }
        )
    }

    func restore(snapshot: CanvasDocumentSnapshot) {
        canvas = snapshot.canvas

        textures.removeAll(keepingCapacity: true)

        for texture in snapshot.textures {
            textures[texture.canvasLayer] = texture
        }
    }

    // MARK: - Layer

    public var device: GPUDevice {
        GPUDevice.default // TODO: document should not know system config?
    }

    var activeLayer: CanvasLayer {
        canvas.layers.first!
    }

    // MARK: - Texture

    private var textures = [CanvasLayer: LayerTexture]()

    private var layerContainer: FileWrapper? {
        file?.fileWrappers?[CanvasDocument.kLayerContainerName]
    }

    func layer(id: String, type: String) -> Data? {
        layerContainer?.fileWrappers?["\(id).\(type)"]?.regularFileContents
    }

    func texture(canvasLayer: CanvasLayer) -> LayerTexture {
        if textures[canvasLayer] == nil {
            textures[canvasLayer] = LayerTexture(canvasLayer: canvasLayer, context: self)
        }
        return textures[canvasLayer]!
    }
}
