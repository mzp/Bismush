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

    func layer(id _: String) -> Data? {
        nil
    }

    let canvas: Canvas

    public static var readableContentTypes: [UTType] {
        [.canvas]
    }

    public static var writableContentTypes: [UTType] {
        [.canvas]
    }

    public static let sample = CanvasDocument()

    public init(canvas: Canvas = .sample) {
        self.canvas = canvas
    }

    public required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.fileWrappers?["Info.json"]?.regularFileContents else {
            fatalError("Invalid file format")
        }
        canvas = try JSONDecoder().decode(Canvas.self, from: data)
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
        /*        for layer in snapshot.artboard.layerRenderers {
             layerContainer.addRegularFile(
                 withContents: layer.data,
                 preferredFilename: "\(layer.canvasLayer.id).layerData"
             )
         }*/
        container.addFileWrapper(layerContainer)

        return container
    }

    // MARK: - Layer

    var device: GPUDevice {
        GPUDevice.default
    }

    var activeLayer: CanvasLayer {
        canvas.layers.first!
    }

    // MARK: - Texture

    private var textures = [String: MTLTexture]()
    private var msaaTextures = [String: MTLTexture]()

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

            if let data = layer(id: canvasLayer.id) {
                let bytesPerRow = MemoryLayout<Float>.size * 4 * width

                _ = data.withUnsafeBytes { pointer in
                    texture.replace(
                        region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0,
                        withBytes: pointer,
                        bytesPerRow: bytesPerRow
                    )
                }
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
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: canvasLayer.pixelFormat,
            width: Int(canvasLayer.size.width),
            height: Int(canvasLayer.size.height),
            mipmapped: false
        )
        desc.textureType = .type2DMultisample
        desc.sampleCount = 4
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device.metalDevice.makeTexture(descriptor: desc)!
        msaaTextures[canvasLayer.id] = texture
        return texture
    }
}
