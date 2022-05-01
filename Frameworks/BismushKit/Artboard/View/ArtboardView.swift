//
//  MetalView.swift
//  Bismush
//
//  Created by mzp on 3/15/22.
//

import MetalKit

open class ArtboardView: MTKView, MTKViewDelegate {
    private let store: ArtboardStore
    private let commandQueue: MTLCommandQueue
    private var viewPortSize: Size<ViewCoordinate> = .zero()
    private let renderer: ArtboardRenderer

    public init(store: ArtboardStore) {
        self.store = store
        commandQueue = store.device.metalDevice.makeCommandQueue()!
        commandQueue.label = "Artboard"
        renderer = ArtboardRenderer(store: store)
        super.init(frame: .zero, device: store.device.metalDevice)
        delegate = self
        clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
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
        guard let buffer = commandQueue.makeCommandBuffer() else {
            return
        }
        buffer.label = "Frame"
        guard let descriptor = currentRenderPassDescriptor else {
            return
        }
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(viewPortSize.width),
            height: Double(viewPortSize.height),
            znear: -1,
            zfar: 1
        )
        encoder.label = "Frame"
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
