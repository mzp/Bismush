//
//  MetalMutableArray.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import Metal

public struct MetalMutableArray<T>: CustomDebugStringConvertible {
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

    public var debugDescription: String {
        array().debugDescription
    }

    func array() -> [T] {
        guard let buffer = content else {
            return []
        }
        return Array(
            UnsafeBufferPointer(start: buffer.contents().bindMemory(to: T.self, capacity: count),
                                count: count)
        )
    }
}
