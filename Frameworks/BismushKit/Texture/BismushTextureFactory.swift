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
            let sparseHeapSizeInBytes = 256 * 1024 * 1024
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

    func create(_ descriptor: BismushTextureDescriptior) -> BismushTexture {
        .init(
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
                rasterSampleCount: 1,
                sparse: false
            ),
            context: self
        )
    }

    func createTexture(
        _ description: BismushTextureDescriptior
    ) -> (MTLTexture, MTLTexture?) {
        BismushLogger.metal.info("Create Texture")
        let width = Int(description.size.width)
        let height = Int(description.size.height)

        let metalTexture = MTLTextureDescriptor()

        if let heap = heap, description.sparse {
            metalTexture.storageMode = heap.storageMode
        }

        let texture = device.makeTexture { metalTexture in
            metalTexture.width = width
            metalTexture.height = height
            metalTexture.pixelFormat = description.pixelFormat
            metalTexture.usage = [.shaderRead, .renderTarget, .shaderWrite]
            metalTexture.textureType = .type2D
        }

        if description.rasterSampleCount > 1 {
            let msaaTexture = device.makeTexture { metalTexture in
                metalTexture.textureType = .type2DMultisample
                metalTexture.width = width
                metalTexture.height = height
                metalTexture.pixelFormat = description.pixelFormat
                metalTexture.sampleCount = description.rasterSampleCount
                metalTexture.usage = [.shaderRead, .renderTarget, .shaderWrite]
                metalTexture.textureType = .type2D
            }
            return (texture!, msaaTexture!)
        } else {
            return (texture!, nil)
        }
    }
}
