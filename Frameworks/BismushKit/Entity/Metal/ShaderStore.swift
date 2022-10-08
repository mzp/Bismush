//
//  ComputeShader.swift
//  Bismush
//
//  Created by mzp on 4/30/22.
//

import Foundation
import Metal

class ShaderStore {
    private let device: GPUDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineStates = [FunctionName: MTLComputePipelineState]()
    init(device: GPUDevice) {
        self.device = device
        commandQueue = device.metalDevice.makeCommandQueue()!
    }

    func compute(_ name: FunctionName, dispatch: (MTLComputeCommandEncoder) -> Void) throws {
        try device.scope(name.rawValue) {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            commandBuffer.label = "\(#function): \(name.rawValue)"
            let encoder = commandBuffer.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(try pipelineState(name))
            dispatch(encoder)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted() // FIXME: use async?
        }
    }

    private func pipelineState(_ name: FunctionName) throws -> MTLComputePipelineState {
        if !pipelineStates.keys.contains(name) {
            let function = device.resource.function(name)
            pipelineStates[name] = try device.metalDevice.makeComputePipelineState(function: function)
        }
        return pipelineStates[name]!
    }
}
