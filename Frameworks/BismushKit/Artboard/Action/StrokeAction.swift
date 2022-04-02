//
//  BrushRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//

import CoreGraphics
import Metal
import simd

public class StrokeAction {
    struct BoundingBox {
        var min: MTLPackedFloat3
        var max: MTLPackedFloat3
    }

    struct StrokeTip {
        var point: SIMD2<Float>
    }

    private let buffer: MTLBuffer
    private let commandQueue: MTLCommandQueue
    private let computePipelineState: MTLComputePipelineState
    private var accelerationStructure: MTLAccelerationStructure!
    private let store: ArtboardStore

    public init(store: ArtboardStore) {
        self.store = store
        buffer = store.device.metalDevice.makeBuffer(
            length: MemoryLayout<StrokeTip>.size,
            options: .storageModeShared
        )!
        commandQueue = store.device.metalDevice.makeCommandQueue()!
        computePipelineState = try! store.device.metalDevice.makeComputePipelineState(
            function: store.device.resource.function(.strokePoint)
        )

        accelerationStructure = rebuild()
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

    // swiftlint:disable function_body_length
    func rebuild() -> MTLAccelerationStructure {
        store.device.scope("\(#function)") {
            var vertecies = [
                BoundingBox(min: .init(.init(elements: (0, 0, 0))),
                            max: .init(.init(elements: (1, 1, 0)))),
            ]

            let vertexBuffer = store.device.metalDevice.makeBuffer(
                bytes: &vertecies,
                length: MemoryLayout<BoundingBox>.stride * vertecies.count,
                options: .storageModeShared
            )

            let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
            if #available(macOS 12.0, iOS 15.0, *) {
                geometryDescriptor.label = "Bounding box"
            }
            geometryDescriptor.boundingBoxCount = 1
            geometryDescriptor.boundingBoxBuffer = vertexBuffer

            let descriptor = MTLPrimitiveAccelerationStructureDescriptor()
            descriptor.geometryDescriptors = [geometryDescriptor]

            let sizes = store.device.metalDevice.accelerationStructureSizes(descriptor: descriptor)
            let scratchBuffer = store.device.metalDevice.makeBuffer(
                length: sizes.buildScratchBufferSize,
                options: .storageModeShared
            )!
            let accelerationStructure = store.device.metalDevice.makeAccelerationStructure(descriptor: descriptor)!
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeAccelerationStructureCommandEncoder()!
            encoder.build(
                accelerationStructure: accelerationStructure,
                descriptor: descriptor,
                scratchBuffer: scratchBuffer,
                scratchBufferOffset: 0
            )

            let compactedSizeBuffer = store.device.metalDevice.makeBuffer(
                length: MemoryLayout<UInt32>.size,
                options: .storageModeShared
            )!
            encoder.writeCompactedSize(
                accelerationStructure: accelerationStructure,
                buffer: compactedSizeBuffer,
                offset: 0
            )
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            let compactedSize: UInt32 = compactedSizeBuffer.contents().load(as: UInt32.self)
            BismushLogger.metal.debug("compacted size: \(compactedSize)")
            let compactedAccelerationStructure = store.device.metalDevice.makeAccelerationStructure(
                size: Int(compactedSize)
            )!
            let commandBuffer2 = commandQueue.makeCommandBuffer()!
            let encoder2 = commandBuffer2.makeAccelerationStructureCommandEncoder()!
            encoder2.copy(
                sourceAccelerationStructure: accelerationStructure,
                destinationAccelerationStructure: compactedAccelerationStructure
            )
            encoder2.endEncoding()
            commandBuffer2.commit()
            commandBuffer2.waitUntilCompleted()
            return compactedAccelerationStructure
        }
    }

    // swiftlint:enable function_body_length

    public func add(point: Point<ViewCoordinate>, viewSize: Size<ViewCoordinate>) {
        BismushLogger.metal.debug("Add stroke <point: \(point), size: \(viewSize)>")
        let strokeTip = strokeTip(position: point, viewSize: viewSize)
        BismushLogger.metal.debug("stroke tip: \(strokeTip.point)")
        drawStroke(tip: strokeTip)
    }

    func strokeTip(position: Point<ViewCoordinate>, viewSize: Size<ViewCoordinate>) -> StrokeTip {
        store.device.scope("\(#function)") {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeComputeCommandEncoder()!
            var position = position
            var size = viewSize
            encoder.setComputePipelineState(computePipelineState)
            encoder.useResource(accelerationStructure, usage: .read)
            encoder.setAccelerationStructure(accelerationStructure, bufferIndex: 0)
            encoder.setBuffer(buffer, offset: 0, index: 1)
            encoder.setBytes(&position, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
            encoder.setBytes(&size, length: MemoryLayout<SIMD2<Float>>.size, index: 3)
            let projection: Transform2D<WorldCoordinate, ViewPortCoordinate> =
                store.projection(viewPortSize: viewSize).inverse
            let modelView: Transform2D<LayerPixelCoordinate, WorldCoordinate> =
                store.activeLayer.transform * store.modelViewMatrix.inverse
            setTransform(encoder: encoder, transform: projection, index: 4)
            setTransform(encoder: encoder, transform: modelView, index: 5)

            encoder.dispatchThreads(
                MTLSize(width: 1, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
            )
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted() // TODO: use async?
        }
        return buffer.contents().load(as: StrokeTip.self)
    }

    func drawStroke(tip: StrokeTip) {
        store.device.scope("\(#function)") {
            let commandBuffer = commandQueue.makeCommandBuffer()!

            let renderPassDescription = MTLRenderPassDescriptor()
            renderPassDescription.colorAttachments[0].texture = store.activeLayer.texture
            renderPassDescription.colorAttachments[0].loadAction = .load
            renderPassDescription.colorAttachments[0].storeAction = .store

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescription)!

            let descriptor = Self.renderPipelineDescriptor
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = store.device.resource.function(.strokeVertex)
            descriptor.fragmentFunction = store.device.resource.function(.strokeFragment)
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

            let point = tip.point
            let vertices = [
                point,
                SIMD2(point.x - 10, point.y + 10),
                SIMD2(point.x + 10, point.y + 10),
            ]
            encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * vertices.count, index: 0)

            let transform: Transform2D<LayerCoordinate, LayerPixelCoordinate> = store.activeLayer.textureTransform
            setTransform(encoder: encoder, transform: transform, index: 1)

            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
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
}
