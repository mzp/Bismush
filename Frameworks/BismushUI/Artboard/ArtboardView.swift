//
//  MetalView.swift
//  Bismush
//
//  Created by mzp on 3/15/22.
//

import BismushKit
import MetalKit

open class ArtboardView: MTKView, MTKViewDelegate {
    private let renderer: CanvasRenderer
    private let commandQueue: CommandQueue
    private var viewPortSize: Size<ViewCoordinate> = .zero()

    public init(document: CanvasDocument) {
        renderer = CanvasRenderer(document: document, pixelFormat: .bgra8Unorm, rasterSampleCount: 1)
        commandQueue = document.device.makeCommandQueue(label: #fileID)
        super.init(frame: .zero, device: document.device.metalDevice)
        delegate = self
        clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        preferredFramesPerSecond = 120
    }

    @available(*, unavailable)
    public required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func mtkView(_: MTKView, drawableSizeWillChange size: CGSize) {
        BismushLogger.event.info("Size changed: \(size.debugDescription)")
        viewPortSize = Size(cgSize: size)
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        let buffer = commandQueue.rawValue.makeCommandBuffer()!
        buffer.label = "Frame"
        guard let descriptor = currentRenderPassDescriptor else {
            return
        }
        let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)!
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(viewPortSize.width),
            height: Double(viewPortSize.height),
            znear: -1,
            zfar: 1
        )
        encoder.label = "Render Frame"
        encoder.setViewport(viewPort)
        renderer.render(context: .init(
            encoder: encoder,
            viewPortSize: viewPortSize
        ))
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
