//
//  StrokeRenderer.swift
//  Bismush
//
//  Created by mzp on 4/3/22.
//

import Foundation
import Metal
import simd

class StrokeRenderer {
    typealias ViewPoint = Point<ViewCoordinate>

    private let commandQueue: MTLCommandQueue
    private let computePipelineState: MTLComputePipelineState
    private let store: ArtboardStore
    private let size: Size<ViewCoordinate>
    private let transform: Transform2D<LayerPixelCoordinate, ViewCoordinate>
    private let projection: Transform2D<LayerCoordinate, LayerPixelCoordinate>
    private var dynamicBuffer: DynamicBuffer

    init(store: ArtboardStore, size: Size<ViewCoordinate>) {
        self.store = store
        self.size = size
        transform =
            store.activeLayer.transform *
            (store.normalize(viewPortSize: size) *
                store.projection(viewPortSize: size) *
                store.modelViewMatrix).inverse
        projection = store.activeLayer.textureTransform

        commandQueue = store.device.metalDevice.makeCommandQueue()!
        computePipelineState = try! store.device.metalDevice.makeComputePipelineState(
            function: store.device.resource.function(.bezierInterpolation)
        )
        dynamicBuffer = DynamicBuffer { count in
            store.device.metalDevice.makeBuffer(
                length: MemoryLayout<SIMD3<Float>>.stride * Int(count),
                options: .storageModeShared
            )!
        }
    }

    static let renderPipelineDescriptor: MTLRenderPipelineDescriptor = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].isBlendingEnabled = true

        // alpha blending
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
        return descriptor
    }()

    func render(
        input0: PenInputEvent,
        input1: PenInputEvent,
        input2: PenInputEvent,
        input3: PenInputEvent
    ) {
        let (buffer, count) = generateVertex(input0: input0, input1: input1, input2: input2, input3: input3)
        draw(buffer: buffer, count: count, size: size)
    }

    func transform(event: PenInputEvent) -> SIMD3<Float> {
        let point = transform * event.point
        return SIMD3(point.rawValue, event.pressure)
    }

    func generateVertex(
        input0: PenInputEvent,
        input1: PenInputEvent,
        input2: PenInputEvent,
        input3: PenInputEvent
    ) -> (MTLBuffer, Int) {
        return store.device.scope("\(#function)") {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(computePipelineState)
            // w -> c
            // view point -> layer pixel
            var point0 = transform(event: input0)
            var point1 = transform(event: input1)
            var point2 = transform(event: input2)
            var point3 = transform(event: input3)

            encoder.setBytes(&point0, length: MemoryLayout<SIMD3<Float>>.size, index: 0)
            encoder.setBytes(&point1, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
            encoder.setBytes(&point2, length: MemoryLayout<SIMD3<Float>>.size, index: 2)
            encoder.setBytes(&point3, length: MemoryLayout<SIMD3<Float>>.size, index: 3)

            let length = simd_distance(point0.xy, point1.xy) +
                simd_distance(point1.xy, point2.xy) +
                simd_distance(point2.xy, point3.xy)
            let count = Int(max(ceil(length / 5), 3))
            dynamicBuffer.use(count: count)

            var delta = 1 / Float(count)
            encoder.setBytes(&delta, length: MemoryLayout<Float>.size, index: 4)
            encoder.setBuffer(dynamicBuffer.content, offset: 0, index: 5)

            encoder.dispatchThreads(
                MTLSize(width: count, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted() // TODO: use async?

            return (dynamicBuffer.content, count)
        }
    }

    func draw(buffer: MTLBuffer, count: Int, size _: Size<ViewCoordinate>) {
        store.device.scope("\(#function)") {
            let commandBuffer = commandQueue.makeCommandBuffer()!

            let renderPassDescription = MTLRenderPassDescriptor()
            renderPassDescription.colorAttachments[0].texture = store.activeLayer.msaaTexture
            renderPassDescription.colorAttachments[0].resolveTexture = store.activeLayer.texture
            renderPassDescription.colorAttachments[0].loadAction = .load
            renderPassDescription.colorAttachments[0].storeAction = .storeAndMultisampleResolve

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescription)!

            let descriptor = Self.renderPipelineDescriptor
            descriptor.sampleCount = store.activeLayer.sampleCount
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = store.device.resource.function(.brushVertex)
            descriptor.fragmentFunction = store.device.resource.function(.brushFragment)
            let renderPipelineState = try! store.device.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            encoder.setRenderPipelineState(renderPipelineState)

            let viewPort = MTLViewport(
                originX: 0,
                originY: 0,
                width: Double(store.canvasSize.width),
                height: Double(store.canvasSize.height),
                znear: -1,
                zfar: 1
            )
            encoder.setViewport(viewPort)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)

            setTransform(encoder: encoder, transform: projection, index: 1)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(count))
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }

    func setTransform<A, B>(encoder: MTLComputeCommandEncoder, transform: Transform2D<A, B>, index: Int) {
        var matrix = transform.matrix
        encoder.setBytes(&matrix, length: MemoryLayout<simd_float4x4>.size, index: index)
    }

    func setTransform<A, B>(encoder: MTLRenderCommandEncoder, transform: Transform2D<A, B>, index: Int) {
        var matrix = transform.matrix
        encoder.setVertexBytes(&matrix, length: MemoryLayout<simd_float4x4>.size, index: index)
    }

    func dump(buffer: MTLBuffer, count: Int) {
        let array = Array(
            UnsafeBufferPointer(start: buffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: count),
                                count: count)
        )
        BismushLogger.dev.debug("\(array)")
    }
}
