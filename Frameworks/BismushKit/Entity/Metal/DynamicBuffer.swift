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
