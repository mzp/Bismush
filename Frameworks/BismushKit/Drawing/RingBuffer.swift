//
//  RingBuffer.swift
//  Bismush
//
//  Created by mzp on 4/10/22.
//

import Foundation

struct RingBuffer<Element>: Sequence, Collection {
    private var contents = [Element]()
    private var capacity: Int
    private var index: Int = 0

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func append(_ element: Element) {
        if contents.count < capacity {
            contents.append(element)
        } else {
            contents[index] = element
            index = (index + 1) % count
        }
    }

    mutating func removeAll() {
        contents.removeAll()
        index = 0
    }

    func makeIterator() -> Iterator {
        Iterator(buffer: self)
    }

    var startIndex: Int { 0 }
    var endIndex: Int { contents.count }

    func index(after index: Int) -> Int {
        Swift.min(index + 1, contents.count)
    }

    subscript(position: Int) -> Element {
        contents[(index + position) % capacity]
    }

    struct Iterator: IteratorProtocol {
        var offset = 0
        var buffer: RingBuffer<Element>

        mutating func next() -> Element? {
            defer { offset += 1 }
            let index = (buffer.index + offset) % buffer.capacity
            if buffer.contents.count <= index {
                return nil
            } else if buffer.capacity <= offset {
                return nil
            } else {
                return buffer.contents[index]
            }
        }
    }
}
