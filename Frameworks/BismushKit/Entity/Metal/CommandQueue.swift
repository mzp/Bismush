//
//  CommandQueue.swift
//  Bismush
//
//  Created by Hiro Mizuno on 10/23/22.
//

import Foundation
import Metal

public struct CommandQueue {
    var device: GPUDevice
    public var rawValue: MTLCommandQueue
    var label: String

    init(device: GPUDevice, rawValue: MTLCommandQueue, label: String) {
        self.device = device
        self.rawValue = rawValue
        self.label = label
        rawValue.label = label
    }

    public func makeSequencialCommandBuffer(label: String) -> SequencialCommandBuffer {
        SequencialCommandBuffer(device: device, rawValue: rawValue.makeCommandBuffer()!, label: label)
    }
}
