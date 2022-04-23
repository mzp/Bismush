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
    private var count: Int

    init(allocator: @escaping (Int) -> MTLBuffer) {
        self.allocator = allocator
        count = 16
        content = allocator(16)
    }

    mutating func use(count newCount: Int) {
        guard count < newCount else {
            return
        }
        while count < newCount {
            count *= 2
        }
        content = allocator(count)
    }
}
