//
//  ResourceLoader.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/24/22.
//

import Metal
import MetalKit

public class GPUDevice {
    public let metalDevice: MTLDevice

    static let `default` = GPUDevice(metalDevice: MTLCreateSystemDefaultDevice()!)

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

    func makeRenderPipelineState(
        build: (inout MTLRenderPipelineDescriptor) throws -> Void
    ) throws -> MTLRenderPipelineState {
        var descriptor = MTLRenderPipelineDescriptor()
        try build(&descriptor)
        return try metalDevice.makeRenderPipelineState(descriptor: descriptor)
    }

    func makeTexture(build: (inout MTLTextureDescriptor) throws -> Void) rethrows -> MTLTexture? {
        var descriptor = MTLTextureDescriptor()
        try build(&descriptor)
        return metalDevice.makeTexture(descriptor: descriptor)
    }

    func shader() -> ShaderStore {
        ShaderStore(device: self)
    }

    func makeArray<T>(count: Int) -> MetalMutableArray<T> {
        MetalMutableArray(device: self, count: count)
    }
}
