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

public class CanvasDocument: ReferenceFileDocument, TextureContext {
    typealias DocumentEncoder = PropertyListEncoder
    typealias DocumentDecoder = PropertyListDecoder

    public static let sample = try! CanvasDocument(canvas: .sample)
    public static let empty = try! CanvasDocument(canvas: .empty)
    static let kLayerContainerName = "Layers"

    public var canvas: Canvas
    private let file: FileWrapper?
    private var textures = [CanvasLayer.ID: BismushTexture]()

    public convenience init(canvas: Canvas = .sample) throws {
        try self.init(file: nil, canvas: canvas)
    }

    init(file: FileWrapper?, canvas: Canvas) throws {
        self.file = file
        self.canvas = canvas
        factory = BismushTextureFactory(device: .default)
        canvasTexture = factory.create(
            size: Size(canvas.size),
            pixelFormat: canvas.pixelFormat
        )

        let decoder = DocumentDecoder()
        var textures = [CanvasLayer.ID: BismushTexture]()

        for layer in canvas.layers {
            BismushLogger.file.info("Create Texture for \(layer.id)")

            if case let .builtin(name: name) = layer.layerType {
                textures[layer.id] = factory.create(builtin: name)
            } else {
                textures[layer.id] = factory.create(
                    size: Size(layer.size),
                    pixelFormat: layer.pixelFormat
                )
            }
        }

        if let container = file?.fileWrappers?[CanvasDocument.kLayerContainerName] {
            for layer in canvas.layers {
                if let data = container.fileWrappers?["\(layer.id).data"]?.regularFileContents {
                    BismushLogger.file.info("Load texture data: \(layer.id)")
                    let snapshot = try decoder.decode(BismushTexture.Snapshot.self, from: data)
                    textures[layer.id]?.restore(from: snapshot)
                }
            }
        }
        self.textures = textures
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

    var needsRenderCanvas = true

    var factory: BismushTextureFactory

    convenience init(file: FileWrapper) throws {
        guard let data = file.fileWrappers?["Info.plist"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        let canvas = try DocumentDecoder().decode(Canvas.self, from: data)
        try self.init(file: file, canvas: canvas)
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
        let encoder = DocumentEncoder()
        encoder.outputFormat = .binary

        // MetaData
        let data = try encoder.encode(snapshot.canvas)
        container.addRegularFile(withContents: data, preferredFilename: "Info.plist")

        // Data
        let layerContainer = FileWrapper(directoryWithFileWrappers: [:])
        layerContainer.preferredFilename = Self.kLayerContainerName

        for (id, texture) in snapshot.textures {
            let data = try encoder.encode(texture)
            layerContainer.addRegularFile(
                withContents: data,
                preferredFilename: "\(id).data"
            )
        }
        container.addFileWrapper(layerContainer)

        return container
    }

    // MARK: - Snapshot

    func snapshot() -> CanvasDocumentSnapshot {
        var snapshots = [CanvasLayer.ID: BismushTexture.Snapshot]()

        for (id, texture) in textures {
            snapshots[id] = texture.takeSnapshot()
        }

        return CanvasDocumentSnapshot(
            canvas: canvas,
            textures: snapshots
        )
    }

    func restore(snapshot: CanvasDocumentSnapshot) {
        canvas = snapshot.canvas

        for (id, texture) in textures {
            if let snapshot = snapshot.textures[id] {
                texture.restore(from: snapshot)
            }
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

    private var layerContainer: FileWrapper? {
        file?.fileWrappers?[CanvasDocument.kLayerContainerName]
    }

    func layer(id: String, type: String) -> Data? {
        layerContainer?.fileWrappers?["\(id).\(type)"]?.regularFileContents
    }

    func texture(canvasLayer layer: CanvasLayer) -> BismushTexture {
        textures[layer.id]!
    }

    // MARK: - Session

    func beginSession() {
        activeTexture = factory.create(
            size: Size(activeLayer.size),
            pixelFormat: activeLayer.pixelFormat
        )
    }

    func commitSession() {
        activeTexture = nil
    }

    var activeTexture: BismushTexture?

    var canvasTexture: BismushTexture
}
