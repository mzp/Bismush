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

    func create(
        size: Size<TextureCoordinate>,
        pixelFormat: MTLPixelFormat,
        rasterSampleCount: Int,
        sparse: Bool
    ) -> BismushTexture {
        .init(
            size: size,
            pixelFormat: pixelFormat,
            rasterSampleCount: rasterSampleCount,
            sparse: heap != nil && sparse,
            context: self
        )
    }

    func create(builtin name: String) -> BismushTexture {
        let texture = device.resource.bultinTexture(name: name)
        return .init(
            texture: texture,
            msaaTexture: nil,
            loadAction: .load,
            rasterSampleCount: 1,
            sparse: false,
            context: self
        )
    }

    func createTexture(
        size: Size<TextureCoordinate>,
        pixelFormat: MTLPixelFormat,
        rasterSampleCount: Int,
        sparse: Bool
    ) -> (MTLTexture, MTLTexture?) {
        BismushLogger.metal.info("Create Texture")
        let width = Int(size.width)
        let height = Int(size.height)

        let description = MTLTextureDescriptor()
        description.width = width
        description.height = height
        description.pixelFormat = pixelFormat
        description.usage = [.shaderRead, .renderTarget, .shaderWrite]
        description.textureType = .type2D

        if let heap = heap, sparse {
            description.storageMode = heap.storageMode
        }

        let texture = device.metalDevice.makeTexture(descriptor: description)!

        if rasterSampleCount > 1 {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: pixelFormat,
                width: width,
                height: height,
                mipmapped: false
            )
            desc.textureType = .type2DMultisample
            desc.sampleCount = rasterSampleCount
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let msaaTexture = device.metalDevice.makeTexture(descriptor: desc)!
            return (texture, msaaTexture)
        } else {
            return (texture, nil)
        }
    }
}
