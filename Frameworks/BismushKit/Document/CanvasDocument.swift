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

    public var canvas: Canvas
    private let file: FileWrapper?

    public static var readableContentTypes: [UTType] {
        [.canvas]
    }

    public static var writableContentTypes: [UTType] {
        [.canvas]
    }

    public static let sample = CanvasDocument()

    public init(canvas: Canvas = .sample) {
        self.canvas = canvas
        file = nil
    }

    public required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.fileWrappers?["Info.json"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        canvas = try JSONDecoder().decode(Canvas.self, from: data)
        file = configuration.file
    }

    public func snapshot(contentType _: UTType) throws -> CanvasDocumentSnapshot {
//        assert(contentType.identifier == "jp.mzp.bismush.canvas")
        snapshot()
    }

    public func fileWrapper(snapshot: CanvasDocumentSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let container = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])

        // MetaData
        let data = try JSONEncoder().encode(snapshot.canvas)
        container.addRegularFile(withContents: data, preferredFilename: "Info.json")

        // Data
        let layerContainer = FileWrapper(directoryWithFileWrappers: [:])
        layerContainer.preferredFilename = Self.kLayerContainerName

        for key in textures.keys {
            if let data = snapshot.textures[key]?.bmkData {
                layerContainer.addRegularFile(
                    withContents: data,
                    preferredFilename: "\(key).texture"
                )
            }
        }
        for key in msaaTextures.keys {
            if let data = snapshot.msaaTextures[key]?.bmkData {
                layerContainer.addRegularFile(
                    withContents: data,
                    preferredFilename: "\(key).msaatexture"
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
            textures: textures,
            msaaTextures: msaaTextures
        )
    }

    func restore(snapshot: CanvasDocumentSnapshot) {
        canvas = snapshot.canvas
        textures = snapshot.textures
        msaaTextures = snapshot.msaaTextures
    }

    // MARK: - Layer

    public var device: GPUDevice {
        GPUDevice.default
    }

    var activeLayer: CanvasLayer {
        canvas.layers.first!
    }

    // MARK: - Texture

    private var textures = [String: MTLTexture]()
    private var msaaTextures = [String: MTLTexture]()

    private var layerContainer: FileWrapper? {
        file?.fileWrappers?[CanvasDocument.kLayerContainerName]
    }

    private func layer(id: String, type: String) -> Data? {
        layerContainer?.fileWrappers?["\(id).\(type)"]?.regularFileContents
    }

    func texture(canvasLayer: CanvasLayer) -> MTLTexture {
        if let texture = textures[canvasLayer.id] {
            return texture
        }
        let texture: MTLTexture
        switch canvasLayer.layerType {
        case .empty:
            let size = canvasLayer.size
            let width = Int(size.width)
            let height = Int(size.height)

            let description = MTLTextureDescriptor()
            description.width = width
            description.height = height
            description.pixelFormat = canvasLayer.pixelFormat
            description.usage = [.shaderRead, .renderTarget, .shaderWrite]
            description.textureType = .type2D

            texture = device.metalDevice.makeTexture(descriptor: description)!

            if let data = layer(id: canvasLayer.id, type: "texture") {
                texture.bmkData = data
            }
        case let .builtin(name: name):
            texture = device.resource.bultinTexture(name: name)
        }
        textures[canvasLayer.id] = texture
        return texture
    }

    func msaaTexture(canvasLayer: CanvasLayer) -> MTLTexture? {
        guard GPUDevice.default.capability.msaa else {
            return nil
        }
        if let texture = msaaTextures[canvasLayer.id] {
            return texture
        }
        let width = Int(canvasLayer.size.width)
        let height = Int(canvasLayer.size.height)

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: canvasLayer.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        desc.textureType = .type2DMultisample
        desc.sampleCount = 4
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device.metalDevice.makeTexture(descriptor: desc)!

        if let data = layer(id: canvasLayer.id, type: "msaatexture") {
            texture.bmkData = data
        }

        msaaTextures[canvasLayer.id] = texture
        return texture
    }
}
