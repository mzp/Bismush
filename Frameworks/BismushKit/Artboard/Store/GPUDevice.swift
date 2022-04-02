//
//  ResourceLoader.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/24/22.
//

import Metal
import MetalKit

public class GPUDevice {
    let metalDevice: MTLDevice
    private var scopes = [String: MTLCaptureScope]()

    lazy var resource: ResourceLoader = .init(device: metalDevice)

    init(metalDevice: MTLDevice) {
        BismushDiagnose.record(device: metalDevice)
        self.metalDevice = metalDevice
    }

    func scope<T>(_ label: String, perform: () -> T) -> T {
        var scope = scopes[label]
        if scope == nil {
            scope = MTLCaptureManager.shared().makeCaptureScope(device: metalDevice)
            scope?.label = label
            scopes[label] = scope
        }
        scope?.begin()
        defer { scope?.end() }
        return perform()
    }
}
