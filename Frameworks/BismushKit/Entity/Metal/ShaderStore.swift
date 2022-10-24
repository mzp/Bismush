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
    private var pipelineStates = [FunctionName: MTLComputePipelineState]()
    init(device: GPUDevice) {
        self.device = device
    }

    func compute(
        _ name: FunctionName,
        commandBuffer: SequencialCommandBuffer,
        dispatch: (MTLComputeCommandEncoder) -> Void
    ) throws {
        try commandBuffer.compute(label: name.rawValue) { encoder in
            BismushLogger.metal.info("\(#function): \(name)")
            encoder.setComputePipelineState(try pipelineState(name))
            dispatch(encoder)
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
