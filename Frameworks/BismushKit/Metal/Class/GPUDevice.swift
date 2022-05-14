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
    lazy var capability: MetalDeviceCapability = .init(device: metalDevice)

    init(metalDevice: MTLDevice) {
        BismushDiagnose.record(device: metalDevice)
        self.metalDevice = metalDevice
    }

    func scope<T>(_ label: String, perform: () throws -> T) rethrows -> T {
        let scope = scope(for: label)
        scope.begin()
        defer { scope.end() }
        return try perform()
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

    func makeComputePipelineState(_ name: FunctionName) throws -> MTLComputePipelineState {
        try metalDevice.makeComputePipelineState(
            function: resource.function(name))
    }

    func shader() -> ShaderStore {
        ShaderStore(device: self)
    }

    func makeArray<T>(options: MTLResourceOptions) -> MetalMutableArray<T> {
        MetalMutableArray(device: self, options: options)
    }
}
