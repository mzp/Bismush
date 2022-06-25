//
//  Capability.swift
//  Bismush
//
//  Created by mzp on 5/8/22.
//

import Foundation

class MetalDeviceCapability {
    private let device: MTLDevice
    init(device: MTLDevice) {
        self.device = device
    }

    var msaa: Bool {
        // Simulator doesn't suport this
        device.supports32BitMSAA
    }

    var nonUniformThreadgroupSize: Bool {
        // Simulator doesn't suport this
        device.supportsFamily(.apple4) ||
            device.supportsFamily(.common3) ||
            device.supportsFamily(.mac2)
    }
}
