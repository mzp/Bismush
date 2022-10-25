//
//  SequencialCommandBuffer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 10/23/22.
//

import Foundation
import Metal

public struct SequencialCommandBuffer {
    var device: GPUDevice
    public var rawValue: MTLCommandBuffer
    var label: String

    var fence: MTLFence
    var scope: Activity.Scope

    init(device: GPUDevice, rawValue: MTLCommandBuffer, label: String) {
        self.device = device
        self.rawValue = rawValue
        self.label = label
        fence = device.makeFence()
        scope = Activity("📥 Sequential CommandBuffer: \(label)").enter()

        rawValue.label = "\(label)"

        BismushLogger.metal.info("\(#function): \(label)")
    }

    public mutating func commit() {
        rawValue.commit()
        rawValue.waitUntilCompleted()
        scope.leave()
    }

    public func render(
        label: String,
        descriptor: MTLRenderPassDescriptor,
        perform: (MTLRenderCommandEncoder) throws -> Void
    ) rethrows {
        var scope = Activity("⚡️\(#function): \(label)").enter()
        defer { scope.leave() }
        let encoder = rawValue.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.label = label
        encoder.waitForFence(fence, before: .vertex)
        try perform(encoder)
        encoder.updateFence(fence, after: .fragment)
        encoder.endEncoding()
    }

    public func resourceState(
        label: String,
        perform: (MTLResourceStateCommandEncoder) throws -> Void
    ) rethrows {
        var scope = Activity("⚡️\(#function): \(label)").enter()
        defer { scope.leave() }
        let encoder = rawValue.makeResourceStateCommandEncoder()!
        encoder.label = label
        #if os(macOS) || targetEnvironment(macCatalyst)
            encoder.wait?(for: fence)
        #else
            encoder.wait(for: fence)
        #endif
        try perform(encoder)
        #if os(macOS) || targetEnvironment(macCatalyst)
            encoder.update?(fence)
        #else
            encoder.update(fence)
        #endif
        encoder.endEncoding()
    }

    public func blit(
        label: String,
        perform: (MTLBlitCommandEncoder) throws -> Void
    ) rethrows {
        var scope = Activity("⚡️\(#function): \(label)").enter()
        defer { scope.leave() }
        let encoder = rawValue.makeBlitCommandEncoder()!
        encoder.label = label
        encoder.waitForFence(fence)
        try perform(encoder)
        encoder.updateFence(fence)
        encoder.endEncoding()
    }

    public func compute(
        label: String,
        perform: (MTLComputeCommandEncoder) throws -> Void
    ) rethrows {
        var scope = Activity("⚡️\(#function): \(label)").enter()
        defer { scope.leave() }
        let encoder = rawValue.makeComputeCommandEncoder()!
        encoder.label = label
        encoder.waitForFence(fence)
        try perform(encoder)
        encoder.updateFence(fence)
        encoder.endEncoding()
    }
}
