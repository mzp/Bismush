//
//  BismushTextureFactory.swift
//  Bismush
//
//  Created by Hiro Mizuno on 8/27/22.
//

import Foundation

class BismushTextureFactory: BismushTextureContext {
    let device: GPUDevice
    private let heap: MTLHeap?

    init(device: GPUDevice) {
        self.device = device

        if device.capability.sparseTexture {
            let descriptor = MTLHeapDescriptor()
            let sparseHeapSizeInBytes = 1 * 1024 * 1024 * 1024
            let sparseTileSize = device.metalDevice.sparseTileSizeInBytes
            let alignedHeapSize = ((sparseHeapSizeInBytes + sparseTileSize - 1) / sparseTileSize) * sparseTileSize
            descriptor.type = .sparse
            descriptor.storageMode = .private
            descriptor.size = alignedHeapSize
            heap = device.metalDevice.makeHeap(descriptor: descriptor)
        } else {
            heap = nil
        }
    }

    func create(_ descriptor: BismushTextureDescriptor) -> BismushTexture {
        var descriptor = descriptor
        if !device.capability.sparseTexture {
            descriptor.tileSize = nil
        }
        return .init(
            descriptor: descriptor,
            context: self
        )
    }

    func create(builtin name: String) -> BismushTexture {
        let texture = device.resource.bultinTexture(name: name)
        return .init(
            texture: texture,
            msaaTexture: nil,
            loadAction: .load,
            descriptor: .init(
                size: .init(width: Float(texture.width), height: Float(texture.height)),
                pixelFormat: texture.pixelFormat,
                rasterSampleCount: 1
            ),
            context: self
        )
    }

    func createTexture(
        _ description: BismushTextureDescriptor
    ) -> (MTLTexture, MTLTexture?) {
        BismushLogger.metal.info("Create Texture")
        let width = Int(description.size.width)
        let height = Int(description.size.height)

        let sparse: MTLHeap? = description.tileSize != nil ? heap : nil
        let texture = device.makeTexture(sparse: sparse) { metalTexture in
            metalTexture.storageMode = sparse?.storageMode ?? .shared
            metalTexture.width = width
            metalTexture.height = height
            metalTexture.pixelFormat = description.pixelFormat
            metalTexture.usage = [.shaderRead, .renderTarget]
            metalTexture.textureType = .type2D
        }

        if description.rasterSampleCount > 1 {
            let msaaTexture = device.makeTexture(sparse: sparse) { metalTexture in
                metalTexture.storageMode = sparse?.storageMode ?? .shared
                metalTexture.textureType = .type2DMultisample
                metalTexture.width = width
                metalTexture.height = height
                metalTexture.pixelFormat = description.pixelFormat
                metalTexture.sampleCount = description.rasterSampleCount
                metalTexture.usage = [.shaderRead, .renderTarget]
            }
            return (texture!, msaaTexture!)
        } else {
            return (texture!, nil)
        }
    }
}
