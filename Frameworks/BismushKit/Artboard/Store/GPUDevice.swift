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
        let scope = scope(for: label)
        scope.begin()
        defer { scope.end() }
        return perform()
    }

    func scope(for label: String) -> MTLCaptureScope {
        var scope = scopes[label]
        if scope == nil {
            scope = MTLCaptureManager.shared().makeCaptureScope(device: metalDevice)
            scope?.label = label
            scopes[label] = scope
        }
        return scope!
    }

    func capture(label _: String, url: URL) throws {
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = metalDevice // scope(for: label)
        captureDescriptor.destination = .gpuTraceDocument
        captureDescriptor.outputURL = url

        try MTLCaptureManager.shared().startCapture(with: captureDescriptor)
    }
}
