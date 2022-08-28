//
//  MetalMutableArray.swift
//  Bismush
//
//  Created by mzp on 7/2/22.
//

import Metal

public struct MetalMutableArray<T>: CustomDebugStringConvertible, Sequence {
    public struct Iterator<T>: IteratorProtocol {
        var content: MTLBuffer?
        var count: Int
        var index: Int = 0

        public mutating func next() -> T? {
            guard index < count else {
                return nil
            }
            guard let buffer = content else {
                return nil
            }
            defer { index += 1 }

            return buffer.contents().advanced(by: index).bindMemory(to: T.self, capacity: 1).pointee
        }
    }

    var content: MTLBuffer?
    private let device: GPUDevice
    private(set) var count = 0
    private var capacity = 0

    var isEmpty: Bool {
        // swiftlint:disable:next empty_count
        count == 0
    }

    init(device: GPUDevice, count: Int) {
        self.device = device

        removeAll(count: count)
    }

    public func makeIterator() -> Iterator<T> {
        Iterator(content: content, count: count)
    }

    mutating func removeAll(count: Int) {
        self.count = count
        capacity = Swift.max(capacity, 1)
        while capacity < count {
            capacity *= 2
        }

        // swiftlint:disable:next empty_count
        if count == 0 {
            content = nil
        } else {
            content = device.metalDevice.makeBuffer(
                length: MemoryLayout<T>.stride * count,
                options: .storageModeShared
            )!
        }
    }

    public var debugDescription: String {
        Array(self).debugDescription
    }
}
