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
    typealias DocumentEncoder = PropertyListEncoder
    typealias DocumentDecoder = PropertyListDecoder

    public static let sample = try! CanvasDocument(canvas: .sample)
    public static let empty = try! CanvasDocument(canvas: .empty)
    static let kLayerContainerName = "Layers"

    public var canvas: Canvas
    private let file: FileWrapper?
    private var textures = [CanvasLayer.ID: BismushTexture]()
    let rasterSampleCount: Int

    public convenience init(canvas: Canvas = .sample) throws {
        try self.init(file: nil, snapshot: CanvasDocumentSnapshot(canvas: canvas, textures: [:]))
    }

    private let kTileSize = TextureTileSize(width: 255, height: 255)

    init(file: FileWrapper?, snapshot: CanvasDocumentSnapshot) throws {
        self.file = file
        canvas = snapshot.canvas
        let device = GPUDevice.default
        factory = BismushTextureFactory(device: device)
        let rasterSampleCount = device.capability.msaa ? 4 : 1
        self.rasterSampleCount = rasterSampleCount

        canvasTexture = factory.create(
            .init(
                size: Size(canvas.size),
                pixelFormat: canvas.pixelFormat,
                rasterSampleCount: rasterSampleCount
            )
        )

        var textures = [CanvasLayer.ID: BismushTexture]()

        for layer in canvas.layers {
            BismushLogger.file.info("Create Texture for \(layer.id)")

            if case let .builtin(name: name) = layer.layerType {
                textures[layer.id] = factory.create(builtin: name)
            } else {
                textures[layer.id] = factory.create(
                    .init(
                        size: Size(layer.size),
                        pixelFormat: layer.pixelFormat,
                        rasterSampleCount: rasterSampleCount,
                        tileSize: kTileSize
                    )
                )
            }
        }
        self.textures = textures

        restore(snapshot: snapshot)
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
        guard let data = file.fileWrappers?["Canvas.plist"]?.regularFileContents else {
            throw InvalidFileFormatError()
        }

        let blobContainer = FileWrapper(directoryWithFileWrappers: [:])
        blobContainer.preferredFilename = "Data"

        let baseDecoder = PropertyListDecoder()
        let decoder = BlobDecoder(fileWrapper: blobContainer, decoder: baseDecoder)
        let snapshot = try decoder.decode(CanvasDocumentSnapshot.self, from: data)
        try self.init(file: file, snapshot: snapshot)
    }

    public func snapshot(contentType: UTType) throws -> CanvasDocumentSnapshot {
        if contentType.identifier != "jp.mzp.bismush.canvas" {
            BismushLogger.file.warning("\(#function) \(contentType) is requested")
        }
        return takeSnapshot()
    }

    public func fileWrapper(snapshot: CanvasDocumentSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let container = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])
        return try flieWrapper(snapshot: snapshot, container: container)
    }

    func flieWrapper(snapshot: CanvasDocumentSnapshot, container: FileWrapper) throws -> FileWrapper {
        let baseEncoder = PropertyListEncoder()
        baseEncoder.outputFormat = .binary

        let blobContainer = FileWrapper(directoryWithFileWrappers: [:])
        blobContainer.preferredFilename = "Data"
        container.addFileWrapper(blobContainer)

        let encoder = BlobEncoder(
            fileWrapper: blobContainer,
            encoder: baseEncoder
        )

        container.addRegularFile(
            withContents: try encoder.encode(snapshot),
            preferredFilename: "Canvas.plist"
        )

        return container
    }

    // MARK: - Snapshot

    func takeSnapshot() -> CanvasDocumentSnapshot {
        var scope = Activity(#function).enter()
        defer { scope.leave() }

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
        needsRenderCanvas = true
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

    struct SessionScope {
        var activity: Activity.Scope
        var capture: MTLCaptureScope
    }

    private var sessionScope: SessionScope?

    func beginSession() {
        assert(activeTexture == nil)

        sessionScope = .init(
            activity: Activity("🖼️ Canvas", options: .detached).enter(),
            capture: device.scope(for: "🖼️ Canvas")
        )

        activeTexture = factory.create(
            .init(
                size: Size(activeLayer.size),
                pixelFormat: activeLayer.pixelFormat,
                rasterSampleCount: rasterSampleCount,
                tileSize: kTileSize
            )
        )
    }

    func commitSession() {
        sessionScope?.activity.leave()
        sessionScope?.capture.end()
        sessionScope = nil
        activeTexture = nil
    }

    var activeTexture: BismushTexture?

    var canvasTexture: BismushTexture
}
