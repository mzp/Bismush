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

    public static let sample = CanvasDocument(canvas: .sample)
    public static let empty = CanvasDocument(canvas: .empty)

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

    public required convenience init(configuration: ReadConfiguration) throws {
        try self.init(file: configuration.file)
    }

    init(file: FileWrapper) throws {
        guard let data = file.fileWrappers?["Info.json"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        canvas = try JSONDecoder().decode(Canvas.self, from: data)
        self.file = file
        _ = texture(canvasLayer: activeLayer)
    }

    public func snapshot(contentType: UTType) throws -> CanvasDocumentSnapshot {
        if contentType.identifier != "jp.mzp.bismush.canvas" {
            BismushLogger.file.warning("\(#function) \(contentType) is requested")
        }
        return snapshot()
    }

    public func fileWrapper(snapshot: CanvasDocumentSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let container = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])
        return try flieWrapper(snapshot: snapshot, container: container)
    }

    func flieWrapper(snapshot: CanvasDocumentSnapshot, container: FileWrapper) throws -> FileWrapper {
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
        GPUDevice.default // FIXME: document should not know system config?
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

    // TODO: activeTexture(layer) -> Texture

    // MARK: - Draw

    func beginSession() {
        activeTexture = LayerTexture(activeLayer: activeLayer, context: self)
    }

    func commitSession() {
        activeTexture = nil
    }

    var activeTexture: LayerTexture?
}
