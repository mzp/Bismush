//
//  BrushRenderer.swift
//  Bismush
//
//  Created by Hiro Mizuno on 3/26/22.
//

import CoreGraphics
import Metal
import simd

public class Brush {
    struct Session {
        var interporater: BezierInterpolate
//        var mixer: WaterColorMix
        var renderer: LayerDrawer
    }

    private var session: Session?

    private var points = RingBuffer<PressurePoint>(capacity: 4)

    public var color: BismushColor {
        get { BismushColor(rawValue: context.value.brushColor) }
        set {
            BismushLogger.drawing.info("""
                Brush color changed: \
            \(newValue.red, format: .fixed(precision: 2)), \
            \(newValue.green, format: .fixed(precision: 2)), \
            \(newValue.blue, format: .fixed(precision: 2)), \
            \(newValue.alpha, format: .fixed(precision: 2)))
            """)

            context.value.brushColor = newValue.rawValue
        }
    }

    private var context: MetalObject<BMKLayerContext>
    private let document: CanvasDocument

    public var brushSize: Float {
        get { context.value.brushSize }
        set { context.value.brushSize = newValue }
    }

    public init(document: CanvasDocument, brushSize: Float = 50) {
        self.document = document

        context = try! document.device.makeObject(BMKLayerContext(
            brushColor: SIMD4<Float>(0, 0, 0, 1),
            currentColor: SIMD4<Float>(0, 0, 0, 1),
            brushSize: brushSize,
            textureProjection: document.activeLayer.textureTransform.matrix,
            layerProjection: document.activeLayer.renderTransform.matrix
        ))
    }

    public func commit() {
        BismushLogger.drawing.debug("\(#function)")

        if points.count < 4 {
            draw(
                input0: points.get(index: 0) ?? points.last ?? .zero,
                input1: points.get(index: 1) ?? points.last ?? .zero,
                input2: points.get(index: 2) ?? points.last ?? .zero,
                input3: points.get(index: 3) ?? points.last ?? .zero
            )
        }
        session = nil
        context.value.currentColor = context.value.brushColor
        points.removeAll()
    }

    public func add(pressurePoint: PressurePoint, viewSize: Size<ViewCoordinate>) {
        BismushLogger.drawing.trace("\(#function): \(pressurePoint)")
        points.append(pressurePoint)

        if session == nil {
            let interporater = BezierInterpolate(document: document, size: viewSize)
//            let mixer = WaterColorMix(document: document, context: context)
            let renderer = LayerDrawer(document: document, context: context)
            session = Session(interporater: interporater, renderer: renderer)
            BismushLogger.drawing.debug("\(#function): Session starts")
        }

        if points.count == 4 {
            let lastPoint = points[3]
            draw(input0: points[0], input1: points[1], input2: points[2], input3: points[3])
            points.removeAll()
            points.append(lastPoint)
        } else {
            let count = points.count
            BismushLogger.drawing.info("Skip brush rendering (stored point=\(count))")
        }
    }

    private func draw(input0: PressurePoint, input1: PressurePoint, input2: PressurePoint, input3: PressurePoint) {
        guard let session = session else {
            assertionFailure()
            return
        }
        let strokes = session.interporater.interpolate(input0: input0, input1: input1, input2: input2, input3: input3)
//        session.mixer.mix(strokes: strokes)
        session.renderer.draw(strokes: strokes)
    }
}
