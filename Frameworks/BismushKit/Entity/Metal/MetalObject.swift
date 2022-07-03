//
//  MetalObject.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import Metal

struct MetalObject<T> {
    var buffer: MTLBuffer
    var value: T {
        get { buffer.contents().bindMemory(to: T.self, capacity: 1).pointee }
        set {
            buffer.contents().storeBytes(of: newValue, as: T.self)
        }
    }
    var device: GPUDevice

    init(_ value: T, device: GPUDevice) throws {
        var value = value
        guard let buffer = device.metalDevice.makeBuffer(bytes: &value, length: MemoryLayout<T>.size, options: .storageModeShared) else {
            throw UnsupportedError()
        }
        self.buffer = buffer
        self.device = device
    }
}

extension GPUDevice {
    func makeObject<T>(_ value: T) throws -> MetalObject<T> {
        try .init(value, device: self)
    }
}
