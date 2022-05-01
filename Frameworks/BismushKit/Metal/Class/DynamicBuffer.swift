//
//  DynamicBuffer.swift
//  Bismush
//
//  Created by mzp on 4/23/22.
//

import Metal

struct DynamicBuffer {
    var allocator: (Int) -> MTLBuffer
    var content: MTLBuffer
    private(set) var count = 0
    private var capacity = 16

    init(allocator: @escaping (Int) -> MTLBuffer) {
        self.allocator = allocator
        content = allocator(capacity)
    }

    mutating func use(count newCount: Int) {
        count = newCount
        guard capacity < newCount else {
            return
        }
        while capacity < newCount {
            capacity *= 2
        }
        content = allocator(capacity)
    }
}

struct MetalMutableArray<T> {
    var content: MTLBuffer?
    private let device: GPUDevice
    private let options: MTLResourceOptions
    private(set) var count = 0
    private var capacity = 0

    var isEmpty: Bool {
        // swiftlint:disable:next empty_count
        count == 0
    }

    init(device: GPUDevice, options: MTLResourceOptions = .storageModeShared) {
        self.device = device
        self.options = options
    }

    mutating func use(count newCount: Int) {
        count = newCount
        guard capacity < newCount else {
            return
        }
        capacity = max(capacity, 1)
        while capacity < newCount {
            capacity *= 2
        }
        content = device.metalDevice.makeBuffer(length: MemoryLayout<T>.stride * count, options: options)!
    }
}
